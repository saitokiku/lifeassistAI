import 'capture_request.dart';

/// One parsed intent out of free text (spoken, typed, pasted, or OCR'd).
class ParsedCapture {
  const ParsedCapture({
    required this.request,
    required this.summary,
    required this.confidence,
  });

  final CaptureRequest request;

  /// Human line for the confirm chip ("$12.50 · coffee beans").
  final String summary;

  /// 0..1 — heuristic certainty; low-confidence items default to idea.
  final double confidence;
}

/// The deterministic engine behind the Capture Inbox: turns anything —
/// "coffee 4.50", "2h deep work", "remind me to stretch at 7am", a
/// pasted bank line, an OCR'd receipt — into typed capture requests.
/// Runs identically on every device; on-device AI can pre-clean input
/// upstream, but nothing depends on it.
///
/// Two rules govern this parser, both learned from real defects:
///
/// 1. **Never lose input.** Every non-blank line produces at least one
///    chip. Lines that look like receipt totals become low-confidence
///    chips the user can keep or discard — they are never dropped.
/// 2. **Never invent.** A time is only read when the text actually
///    marks one (`at`, `am/pm`, or `h:mm`); a bare number in "buy 2
///    apples" is part of the user's words, not a 2 a.m. reminder.
class CaptureParser {
  CaptureParser._();

  /// An amount, with optional thousands grouping and optional decimals.
  /// `1,234.56`, `1.234,56`, `1 234,56`, `4.50`, `4,50`, `1200`.
  /// The old pattern allowed only two trailing decimals and demanded
  /// whitespace immediately after, so every grouped amount — i.e. every
  /// real bank line — failed to match at all.
  static final _money = RegExp(
    r'(?<![\w.,])'
    r'-?\$?\s?'
    r'(\d{1,3}(?:[ ,.]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)'
    r'(?![\w])',
  );
  static final _moneyWord = RegExp(
      r'\b(spent|paid|bought|expense|cost|costs|price|bill)\b',
      caseSensitive: false);
  static final _hours = RegExp(
      r'(?<![\w.])(\d{1,2}(?:[.,]\d{1,2})?)\s*(?:h|hr|hrs|hours?)(?![\w])',
      caseSensitive: false);
  static final _minutes = RegExp(
      r'(?<![\w.])(\d{1,3})\s*(?:m|min|mins|minutes?)(?![\w])',
      caseSensitive: false);
  static final _remind =
      RegExp(r'\bremind(?:er)?\b|\bremind me\b', caseSensitive: false);

  /// A candidate time. Accepted only when the text actually MARKS one —
  /// a meridiem, a `:mm`, or a leading "at" (see [_readClock]). A bare
  /// number in "buy 2 apples" is the user's words, not 2 a.m.
  static final _clock = RegExp(
    r'(?<at>\bat\s+)?\b(?<h>\d{1,2})(?::(?<m>\d{2}))?\s*(?<mer>am|pm)?\b',
    caseSensitive: false,
  );

  /// Receipt/statement summary rows. These become low-confidence chips
  /// rather than disappearing: a line like "Total rethink of the launch
  /// plan" is prose, not a receipt total, and used to vanish silently
  /// from any multi-line capture.
  static final _receiptNoise = RegExp(
      r'^(subtotal|total|tax|change|cash|card|visa|mastercard|balance|'
      r'amount due)\b',
      caseSensitive: false);

  /// Splits multi-line input (pastes, OCR) and parses each line; single
  /// lines parse whole. A line carrying both a duration and an amount
  /// yields BOTH chips. Never returns empty for non-blank input.
  static List<ParsedCapture> parse(String raw) {
    final lines = raw
        .split(RegExp(r'[\n;]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];

    final results = <ParsedCapture>[];
    for (final line in lines) {
      results.addAll(_parseLine(line));
    }
    if (results.isEmpty) results.add(_fallback(raw.trim()));
    return results;
  }

  /// Zero or more captures for one line. Reminders are exclusive (the
  /// whole line is the reminder); otherwise a line may yield a time
  /// block and an expense together.
  static List<ParsedCapture> _parseLine(String line) {
    // Reminders first — "remind me to stretch at 7am".
    if (_remind.hasMatch(line)) return [_reminder(line)];

    // A receipt summary row is "TOTAL 7.96" — the marker word AND an
    // amount. Those are dropped, as before, so an OCR'd receipt yields
    // only its line items. But a line that merely STARTS with one of
    // those words and carries no amount is prose ("Total rethink of the
    // launch plan", "Cash flow ideas for next quarter") and used to
    // vanish from any multi-line capture; it now falls through to a
    // normal idea chip.
    if (_receiptNoise.hasMatch(line) &&
        _expense(line, lowConfidence: true) != null) {
      return const [];
    }

    // "coffee 4.50 and 2h deep work" is two captures, and each deserves
    // its own words — not the whole line twice. Split on connectors,
    // but ONLY when every segment independently parses as a typed
    // capture; otherwise "bread and butter 4.50" would lose "bread".
    // `,(?!\d)` so a thousands separator ("1,234.56") is never a
    // segment boundary, while "coffee 4.50, 2h work" still splits.
    final segments = line
        .split(RegExp(r'\s+and\s+|\s*,(?!\d)\s*', caseSensitive: false))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.length > 1) {
      final typed = [for (final s in segments) _typed(s)];
      if (!typed.contains(null)) return typed.cast<ParsedCapture>();
    }

    final out = <ParsedCapture>[];

    // Hours → time block ("2h deep work", "90 min admin").
    final time = _time(line);
    if (time != null) out.add(time.capture);

    // Money → expense, parsed from what the time chip didn't consume,
    // so a single unsplittable line still yields both. First-match-wins
    // used to drop the amount entirely.
    final expense = _expense(time?.remainder ?? line, lowConfidence: false);
    if (expense != null) out.add(expense);

    if (out.isEmpty) out.add(_fallback(line));
    return out;
  }

  /// A time or expense capture for [s], or null when it is neither —
  /// the test that decides whether a line is safe to split.
  static ParsedCapture? _typed(String s) {
    final time = _time(s);
    if (time != null) return time.capture;
    return _expense(s, lowConfidence: false);
  }

  /// The first genuinely-marked time in [s], or null. Scans every
  /// candidate rather than giving up on the first bare number, so
  /// "buy 2 apples at 7am" still finds 7am.
  static ({int hour, int minute, String matched})? _readClock(String s) {
    for (final m in _clock.allMatches(s)) {
      final marked = m.namedGroup('at') != null ||
          m.namedGroup('m') != null ||
          m.namedGroup('mer') != null;
      if (!marked) continue;
      var hour = int.tryParse(m.namedGroup('h') ?? '');
      final minute = int.tryParse(m.namedGroup('m') ?? '0') ?? 0;
      if (hour == null) continue;
      final meridiem = m.namedGroup('mer')?.toLowerCase();
      if (meridiem == 'pm' && hour < 12) hour += 12;
      if (meridiem == 'am' && hour == 12) hour = 0;
      if (hour > 23 || minute > 59) continue;
      return (hour: hour, minute: minute, matched: m[0]!);
    }
    return null;
  }

  static ParsedCapture _reminder(String line) {
    var text = line
        .replaceFirst(
            RegExp(r'.*?\bremind (?:me )?(?:to )?', caseSensitive: false), '')
        .trim();
    final clock = _readClock(text) ?? _readClock(line);
    int? hour;
    int? minute;
    if (clock != null) {
      hour = clock.hour;
      minute = clock.minute;
      text = text.replaceFirst(clock.matched, ' ');
    }
    text = _tidy(text);
    if (text.isEmpty) text = 'Reminder';
    return ParsedCapture(
      request: CaptureRequest(
        type: CaptureType.reminder,
        text: text,
        hour: hour,
        minute: hour == null ? null : minute,
      ),
      summary: hour == null
          ? 'Reminder · $text'
          : 'Reminder · $text · ${hour.toString().padLeft(2, '0')}:'
              '${(minute ?? 0).toString().padLeft(2, '0')}',
      confidence: 0.9,
    );
  }

  static ({ParsedCapture capture, String remainder})? _time(String line) {
    final hours = _hours.firstMatch(line);
    final minutes = _minutes.firstMatch(line);
    if (hours == null && minutes == null) return null;

    final double value;
    final String consumed;
    if (hours != null) {
      value = double.parse(hours[1]!.replaceAll(',', '.'));
      consumed = hours[0]!;
    } else {
      value = int.parse(minutes![1]!) / 60.0;
      consumed = minutes[0]!;
    }
    if (value <= 0 || value > 24) return null;

    final remainder = line.replaceFirst(consumed, ' ');
    final note = _tidy(remainder);
    return (
      capture: ParsedCapture(
        request: CaptureRequest(
          type: CaptureType.time,
          hours: value,
          text: note.isEmpty ? null : note,
          category: note.isEmpty ? null : note,
        ),
        summary: '${_trimNum(value)}h${note.isEmpty ? '' : ' · $note'}',
        confidence: 0.85,
      ),
      remainder: remainder,
    );
  }

  static ParsedCapture? _expense(String line, {required bool lowConfidence}) {
    final money = _money.firstMatch(line);
    if (money == null) return null;
    final raw = money[1]!;
    // A bare integer is only money when the line says so ($ or a
    // spending word) or the number carries decimals/grouping.
    final looksLikeMoney = line.contains(r'$') ||
        _moneyWord.hasMatch(line) ||
        RegExp(r'[.,]').hasMatch(raw);
    if (!looksLikeMoney) return null;

    final amount = _amount(raw);
    if (amount == null || amount <= 0 || amount >= 1000000) return null;

    final description = _tidy(
      line.replaceFirst(money[0]!, ' ').replaceAll(_moneyWord, ' '),
    );
    return ParsedCapture(
      request: CaptureRequest(
        type: CaptureType.expense,
        amount: amount,
        text: description.isEmpty ? null : description,
        category: description.isEmpty ? null : description,
      ),
      summary: '\$${amount.toStringAsFixed(2)}'
          '${description.isEmpty ? '' : ' · $description'}',
      confidence: lowConfidence ? 0.35 : 0.8,
    );
  }

  /// `1,234.56` / `1.234,56` / `1 234,56` / `4,50` / `1200` → double.
  /// Mirrors Validators.normalizeDecimal: when both separators appear
  /// the last one is the decimal point; a lone separator followed by
  /// exactly three digits is grouping.
  static double? _amount(String raw) {
    var s = raw.replaceAll(' ', '');
    final lastDot = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');
    if (lastDot >= 0 && lastComma >= 0) {
      if (lastComma > lastDot) {
        s = s.replaceAll('.', '');
        final i = s.lastIndexOf(',');
        s = '${s.substring(0, i)}.${s.substring(i + 1)}';
      } else {
        s = s.replaceAll(',', '');
      }
    } else {
      final sep = lastDot >= 0 ? lastDot : lastComma;
      if (sep >= 0) {
        final tail = s.length - sep - 1;
        s = tail == 3
            ? s.replaceRange(sep, sep + 1, '') // grouping: 1,200
            : s.replaceRange(sep, sep + 1, '.'); // decimals: 4,50
      }
    }
    return double.tryParse(s);
  }

  /// Collapses whitespace and trims connector punctuation left behind
  /// when a match is cut out of the middle of a sentence.
  static String _tidy(String s) => s
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^(?:\s|[-·:,]|\b(?:and|for|on)\b)+',
          caseSensitive: false), '')
      .replaceAll(RegExp(r'(?:\s|[-·:,]|\b(?:and|for|on)\b)+$',
          caseSensitive: false), '')
      .trim();

  static ParsedCapture _fallback(String text, {bool lowConfidence = false}) {
    // Free text reads like a thought → idea keeps it safe; the chip lets
    // the user reroute before saving. Receipt-shaped rows land here too
    // rather than being discarded.
    return ParsedCapture(
      request: CaptureRequest(type: CaptureType.idea, text: text),
      summary:
          'Idea · ${text.length > 44 ? '${text.substring(0, 43)}…' : text}',
      confidence: lowConfidence ? 0.2 : 0.4,
    );
  }

  static String _trimNum(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

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
class CaptureParser {
  CaptureParser._();

  static final _money = RegExp(
      r'(?:^|\s)[-]?\$?\s?(\d{1,6}(?:[.,]\d{2})?)(?=\s|$)');
  static final _moneyWord = RegExp(
      r'\b(spent|paid|bought|expense|cost|for)\b',
      caseSensitive: false);
  static final _hours = RegExp(
      r'\b(\d{1,2}(?:[.,]\d{1,2})?)\s*(?:h|hr|hrs|hours?)\b',
      caseSensitive: false);
  static final _minutes = RegExp(r'\b(\d{1,3})\s*(?:m|min|mins|minutes?)\b',
      caseSensitive: false);
  static final _remind =
      RegExp(r'\bremind(?:er)?\b|\bremind me\b', caseSensitive: false);
  static final _clock = RegExp(
      r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
      caseSensitive: false);
  static final _receiptNoise = RegExp(
      r'^(subtotal|total|tax|change|cash|card|visa|mastercard|balance|amount due)\b',
      caseSensitive: false);

  /// Splits multi-line input (pastes, OCR) and parses each line; single
  /// lines parse whole. Empty result never happens for non-blank input —
  /// unclassifiable text lands as an idea (short) or note (long).
  static List<ParsedCapture> parse(String raw) {
    final lines = raw
        .split(RegExp(r'[\n;]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];

    final results = <ParsedCapture>[];
    for (final line in lines) {
      final item = _parseLine(line);
      if (item != null) results.add(item);
    }
    if (results.isEmpty) {
      results.add(_fallback(raw.trim()));
    }
    return results;
  }

  static ParsedCapture? _parseLine(String line) {
    // Receipt/statement noise rows add nothing.
    if (_receiptNoise.hasMatch(line)) return null;

    // Reminders first — "remind me to stretch at 7am".
    if (_remind.hasMatch(line)) {
      var text = line
          .replaceFirst(RegExp(r'.*?\bremind (?:me )?(?:to )?',
              caseSensitive: false), '')
          .trim();
      int? hour;
      int? minute;
      final clock = _clock.firstMatch(text) ?? _clock.firstMatch(line);
      if (clock != null) {
        hour = int.tryParse(clock[1]!);
        minute = int.tryParse(clock[2] ?? '0');
        final meridiem = clock[3]?.toLowerCase();
        if (hour != null) {
          if (meridiem == 'pm' && hour < 12) hour += 12;
          if (meridiem == 'am' && hour == 12) hour = 0;
          if (hour > 23) hour = null;
        }
        text = text.replaceFirst(clock[0]!, '').trim();
      }
      if (text.isEmpty) text = 'Reminder';
      return ParsedCapture(
        request: CaptureRequest(
          type: CaptureType.reminder,
          text: text,
          hour: hour,
          minute: minute,
        ),
        summary: hour == null
            ? 'Reminder · $text'
            : 'Reminder · $text · '
                '${hour.toString().padLeft(2, '0')}:'
                '${(minute ?? 0).toString().padLeft(2, '0')}',
        confidence: 0.9,
      );
    }

    // Hours → time block ("2h deep work", "90 min admin").
    final hours = _hours.firstMatch(line);
    final minutes = _minutes.firstMatch(line);
    if (hours != null || minutes != null) {
      double value;
      String consumed;
      if (hours != null) {
        value = double.parse(hours[1]!.replaceAll(',', '.'));
        consumed = hours[0]!;
      } else {
        value = int.parse(minutes![1]!) / 60.0;
        consumed = minutes[0]!;
      }
      if (value > 0 && value <= 24) {
        final note = line.replaceFirst(consumed, '').trim();
        return ParsedCapture(
          request: CaptureRequest(
            type: CaptureType.time,
            hours: value,
            text: note.isEmpty ? null : note,
            category: note.isEmpty ? null : note,
          ),
          summary:
              '${_trimNum(value)}h${note.isEmpty ? '' : ' · $note'}',
          confidence: 0.85,
        );
      }
    }

    // Money → expense ("coffee 4.50", "$1,200 rent", "spent 30 on gas").
    final money = _money.firstMatch(line);
    if (money != null &&
        (_moneyWord.hasMatch(line) ||
            line.contains(r'$') ||
            money[1]!.contains('.') ||
            money[1]!.contains(','))) {
      final amount =
          double.tryParse(money[1]!.replaceAll(',', '.'));
      if (amount != null && amount > 0 && amount < 1000000) {
        final description = line
            .replaceFirst(money[0]!, ' ')
            .replaceAll(_moneyWord, ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll(RegExp(r'^[\s\-·:]+|[\s\-·:]+$'), '')
            .trim();
        return ParsedCapture(
          request: CaptureRequest(
            type: CaptureType.expense,
            amount: amount,
            text: description.isEmpty ? null : description,
            category: description.isEmpty ? null : description,
          ),
          summary:
              '\$${amount.toStringAsFixed(2)}${description.isEmpty ? '' : ' · $description'}',
          confidence: 0.8,
        );
      }
    }

    return _fallback(line);
  }

  static ParsedCapture _fallback(String text) {
    // Long free text reads like a thought → idea keeps it safe; the
    // chip lets the user reroute before saving.
    return ParsedCapture(
      request: CaptureRequest(type: CaptureType.idea, text: text),
      summary:
          'Idea · ${text.length > 44 ? '${text.substring(0, 43)}…' : text}',
      confidence: 0.4,
    );
  }

  static String _trimNum(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

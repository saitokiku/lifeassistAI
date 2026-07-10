import 'package:csv/csv.dart';

/// Pure CSV → transaction-row logic for bank statement import.
///
/// No I/O and no database in here — the sheet feeds it file text plus the
/// user's column mapping, and it hands back parsed rows and honest skip
/// counts. Every bank exports differently; this handles the wide middle:
/// comma/semicolon/tab delimiters, common date formats, negative-debit
/// and positive-debit conventions, currency symbols, and thousands
/// separators.
class CsvImport {
  CsvImport._();

  /// Parses raw CSV text into a rectangular table. Returns empty on junk.
  static List<List<String>> parse(String raw) {
    if (raw.trim().isEmpty) return const [];
    // Pick the delimiter that yields the widest first row.
    List<List<String>> best = const [];
    var bestWidth = 1;
    for (final delimiter in const [',', ';', '\t']) {
      try {
        final rows = const CsvToListConverter(shouldParseNumbers: false)
            .convert(raw, fieldDelimiter: delimiter, eol: '\n')
            .map((r) => [for (final c in r) c.toString().trim()])
            .where((r) => r.any((c) => c.isNotEmpty))
            .toList();
        if (rows.isNotEmpty && rows.first.length > bestWidth) {
          best = rows;
          bestWidth = rows.first.length;
        }
      } catch (_) {
        // Try the next delimiter.
      }
    }
    return best;
  }

  /// Whether the first row looks like column headers rather than data.
  static bool looksLikeHeader(List<String> row) {
    if (row.isEmpty) return false;
    var wordy = 0;
    for (final cell in row) {
      if (cell.isNotEmpty &&
          tryParseDate(cell) == null &&
          tryParseAmount(cell) == null) {
        wordy++;
      }
    }
    return wordy >= (row.length + 1) ~/ 2;
  }

  /// Best-guess column indexes from header names, falling back to type
  /// sniffing on the first data row.
  static ({int? date, int? amount, int? description}) guessMapping(
    List<List<String>> table,
  ) {
    if (table.isEmpty) return (date: null, amount: null, description: null);
    int? date, amount, description;

    if (looksLikeHeader(table.first)) {
      final headers = [for (final h in table.first) h.toLowerCase()];
      int? find(List<String> needles) {
        for (final (i, h) in headers.indexed) {
          for (final n in needles) {
            if (h.contains(n)) return i;
          }
        }
        return null;
      }

      date = find(['date', 'posted', 'transaction date']);
      amount = find(['amount', 'debit', 'value', 'charge']);
      description =
          find(['description', 'memo', 'payee', 'merchant', 'name', 'details']);
    }

    // Type-sniff whatever the headers didn't pin down.
    final sample = table.length > 1 && looksLikeHeader(table.first)
        ? table[1]
        : table.first;
    for (final (i, cell) in sample.indexed) {
      if (date == null && tryParseDate(cell) != null) {
        date = i;
      } else if (amount == null && tryParseAmount(cell) != null) {
        amount = i;
      } else if (description == null &&
          cell.isNotEmpty &&
          tryParseDate(cell) == null &&
          tryParseAmount(cell) == null) {
        description = i;
      }
    }
    return (date: date, amount: amount, description: description);
  }

  /// `2026-07-04`, `07/04/2026`, `04.07.2026`, `Jul 4, 2026`…
  /// Ambiguous a/b/yyyy resolves as month-first unless impossible.
  static DateTime? tryParseDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final iso = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})').firstMatch(s);
    if (iso != null) {
      return _validDate(int.parse(iso.group(1)!), int.parse(iso.group(2)!),
          int.parse(iso.group(3)!));
    }

    final dmy =
        RegExp(r'^(\d{1,2})([-/.])(\d{1,2})[-/.](\d{2,4})$').firstMatch(s);
    if (dmy != null) {
      final a = int.parse(dmy.group(1)!);
      final separator = dmy.group(2)!;
      final b = int.parse(dmy.group(3)!);
      var year = int.parse(dmy.group(4)!);
      if (year < 100) year += 2000;
      // Slashes usually mean US month-first; dots are the European
      // day-first convention. Fall back to the other order when the
      // preferred one is impossible.
      return separator == '.'
          ? _validDate(year, b, a) ?? _validDate(year, a, b)
          : _validDate(year, a, b) ?? _validDate(year, b, a);
    }

    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final named = RegExp(r'^([A-Za-z]{3,9})\.?\s+(\d{1,2}),?\s+(\d{4})$')
        .firstMatch(s);
    if (named != null) {
      final month = months[named.group(1)!.toLowerCase().substring(0, 3)];
      if (month != null) {
        return _validDate(
            int.parse(named.group(3)!), month, int.parse(named.group(2)!));
      }
    }
    return null;
  }

  static DateTime? _validDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final d = DateTime(year, month, day);
    // DateTime silently rolls over (Feb 30 → Mar 2); reject those.
    if (d.month != month || d.day != day) return null;
    return d;
  }

  /// `-$1,234.56`, `(45.00)`, `12,34 €` → signed double.
  static double? tryParseAmount(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    var negative = false;
    if (s.startsWith('(') && s.endsWith(')')) {
      negative = true;
      s = s.substring(1, s.length - 1);
    }
    s = s.replaceAll(RegExp(r'[^\d,.\-+]'), '');
    if (s.isEmpty) return null;
    if (s.startsWith('-')) {
      negative = true;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    // European decimal comma: last separator wins as the decimal point.
    if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
      s = s.replaceAll('.', '');
      final idx = s.lastIndexOf(',');
      s = s.replaceRange(idx, idx + 1, '.');
    }
    s = s.replaceAll(',', '');
    final value = double.tryParse(s);
    if (value == null) return null;
    return negative ? -value : value;
  }

  /// Extracts spend rows using [mapping]. Bank conventions differ on sign:
  /// when most amounts are negative, debits are the negative ones and the
  /// sign flips; otherwise positive amounts are taken as spend. Deposits
  /// (the other sign) are skipped and counted.
  static CsvExtraction extract(
    List<List<String>> table, {
    required int dateColumn,
    required int amountColumn,
    int? descriptionColumn,
  }) {
    final rows = <CsvRow>[];
    var skippedUnparsed = 0;
    var skippedDeposits = 0;

    final dataRows =
        table.isNotEmpty && looksLikeHeader(table.first)
            ? table.sublist(1)
            : table;

    // Sign convention: majority negative → negative means spend.
    var negatives = 0, positives = 0;
    for (final row in dataRows) {
      if (amountColumn >= row.length) continue;
      final amount = tryParseAmount(row[amountColumn]);
      if (amount == null) continue;
      if (amount < 0) {
        negatives++;
      } else if (amount > 0) {
        positives++;
      }
    }
    final negativeMeansSpend = negatives >= positives;

    for (final row in dataRows) {
      if (dateColumn >= row.length || amountColumn >= row.length) {
        skippedUnparsed++;
        continue;
      }
      final date = tryParseDate(row[dateColumn]);
      final amount = tryParseAmount(row[amountColumn]);
      if (date == null || amount == null || amount == 0) {
        skippedUnparsed++;
        continue;
      }
      final isSpend = negativeMeansSpend ? amount < 0 : amount > 0;
      if (!isSpend) {
        skippedDeposits++;
        continue;
      }
      final description = descriptionColumn != null &&
              descriptionColumn < row.length
          ? row[descriptionColumn].trim()
          : '';
      rows.add(CsvRow(date: date, amount: amount.abs(),
          description: description));
    }
    return CsvExtraction(
      rows: rows,
      skippedUnparsed: skippedUnparsed,
      skippedDeposits: skippedDeposits,
    );
  }

  /// Duplicate key: same day, same cents, same normalized description.
  static String duplicateKey(
          {required String dateKey,
          required double amount,
          required String description}) =>
      '$dateKey|${amount.toStringAsFixed(2)}|'
      '${description.trim().toLowerCase()}';
}

class CsvRow {
  const CsvRow({
    required this.date,
    required this.amount,
    required this.description,
  });

  final DateTime date;
  final double amount;
  final String description;
}

class CsvExtraction {
  const CsvExtraction({
    required this.rows,
    required this.skippedUnparsed,
    required this.skippedDeposits,
  });

  final List<CsvRow> rows;
  final int skippedUnparsed;
  final int skippedDeposits;
}

/// Form validators. Return null when valid, message when not.
class Validators {
  Validators._();

  /// Upper bound for any typed number (money, hours, metrics). Keeps
  /// absurd magnitudes out of cents math and the database.
  static const double maxMagnitude = 999999999;

  /// Accepts both decimal conventions before parsing: `4.50`, `4,50`,
  /// `1,200`, `1,234.56`, `1.234,56`. When both separators appear, the
  /// last one is the decimal point and the other is grouping. With
  /// commas only, a final group of 1–2 digits reads as decimals
  /// ("4,50" → 4.50) and anything else as grouping ("1,200" → 1200).
  ///
  /// This exists because the decimal key on most European and Latin
  /// American keyboards types `,` — dropping or ignoring it turned
  /// "4,50" into 450, a silent 100× overstatement on every money field.
  static String normalizeDecimal(String raw) {
    var s = raw.trim();
    final lastComma = s.lastIndexOf(',');
    if (lastComma < 0) return s;
    final lastDot = s.lastIndexOf('.');
    if (lastDot >= 0) {
      if (lastComma > lastDot) {
        // European: dots group, the final comma is the decimal point.
        s = s.replaceAll('.', '');
        final i = s.lastIndexOf(',');
        s = '${s.substring(0, i)}.${s.substring(i + 1)}';
      }
      return s.replaceAll(',', '');
    }
    final decimals = s.length - lastComma - 1;
    if (decimals >= 1 && decimals <= 2 && s.indexOf(',') == lastComma) {
      return '${s.substring(0, lastComma)}.${s.substring(lastComma + 1)}';
    }
    return s.replaceAll(',', '');
  }

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  static String? number(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    final parsed = double.tryParse(normalizeDecimal(value));
    if (parsed == null) {
      return '$label must be a number.';
    }
    if (parsed.abs() > maxMagnitude) return '$label is too large.';
    return null;
  }

  static String? nonNegativeNumber(String? value, {String label = 'Value'}) {
    final base = number(value, label: label);
    if (base != null) return base;
    if (parseNumber(value!) < 0) return '$label cannot be negative.';
    return null;
  }

  static String? positiveNumber(String? value, {String label = 'Value'}) {
    final base = number(value, label: label);
    if (base != null) return base;
    if (parseNumber(value!) <= 0) return '$label must be above zero.';
    return null;
  }

  /// Optional field: valid when empty, otherwise must parse as a number.
  static String? optionalNumber(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) return null;
    return number(value, label: label);
  }

  static double parseNumber(String value) =>
      double.parse(normalizeDecimal(value));

  static double? tryParseNumber(String? value) =>
      value == null || value.trim().isEmpty
          ? null
          : double.tryParse(normalizeDecimal(value));
}

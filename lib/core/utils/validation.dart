/// Form validators. Return null when valid, message when not.
class Validators {
  Validators._();

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  static String? number(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    if (double.tryParse(value.trim()) == null) {
      return '$label must be a number.';
    }
    return null;
  }

  static String? nonNegativeNumber(String? value, {String label = 'Value'}) {
    final base = number(value, label: label);
    if (base != null) return base;
    if (double.parse(value!.trim()) < 0) return '$label cannot be negative.';
    return null;
  }

  static String? positiveNumber(String? value, {String label = 'Value'}) {
    final base = number(value, label: label);
    if (base != null) return base;
    if (double.parse(value!.trim()) <= 0) return '$label must be above zero.';
    return null;
  }

  /// Optional field: valid when empty, otherwise must parse as a number.
  static String? optionalNumber(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) return null;
    if (double.tryParse(value.trim()) == null) {
      return '$label must be a number.';
    }
    return null;
  }

  static double parseNumber(String value) => double.parse(value.trim());

  static double? tryParseNumber(String? value) =>
      value == null || value.trim().isEmpty
          ? null
          : double.tryParse(value.trim());
}

import 'package:intl/intl.dart';

/// The currency symbols offered in Settings, and the default derived
/// from the device locale.
///
/// This is a **display** setting only. Amounts are stored as integer
/// cents in a single currency; the app does no conversion and holds no
/// exchange rates, so changing the symbol relabels existing figures
/// rather than converting them. Settings says so plainly.
class CurrencyOptions {
  CurrencyOptions._();

  /// Offered in the picker, commonest first. "Other" is covered by the
  /// free-text field, so this list only needs to cover the bulk.
  static const symbols = <String>[
    r'$', '€', '£', '¥', '₹', 'CHF', 'kr', 'R\$', 'A\$', 'C\$', '₩', '₺',
    '₽', 'zł', '₱', 'R', '₪', 'Kč', 'RM', '฿',
  ];

  /// The symbol `intl` associates with [locale], falling back to `$`.
  /// Uses the locale's own currency formatter, so a device set to
  /// de-DE starts on €, ja-JP on ¥, and so on.
  static String symbolForLocale(String? locale) {
    if (locale == null || locale.isEmpty) return r'$';
    try {
      final symbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;
      return symbol.isEmpty ? r'$' : symbol;
    } catch (_) {
      // Unknown locale — the default is as good a guess as any.
      return r'$';
    }
  }
}

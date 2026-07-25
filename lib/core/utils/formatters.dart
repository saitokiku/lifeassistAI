import 'package:intl/intl.dart';

/// Display formatting. Keep numbers large and unambiguous.
///
/// **Currency is configurable.** It used to be a hardcoded `$` with
/// `decimalDigits: 0`, which meant two things: nobody outside the US
/// could see their own money, and every aggregate was rounded to whole
/// units — so a `warnOverZero` category could render the self-
/// contradicting "spend is $0. Target is $0.", and an account balance
/// never matched the bank app that produced it.
///
/// [configureCurrency] is called once at startup from the user's saved
/// preference (defaulting to the device locale), so the symbol and the
/// decimal/grouping separators follow the user, not the developer.
class Formatters {
  Formatters._();

  static String _symbol = r'$';
  static String? _locale;

  /// Sets the symbol and number locale used by every money formatter.
  /// Safe to call again when the user changes the setting.
  static void configureCurrency({required String symbol, String? locale}) {
    _symbol = symbol;
    _locale = locale;
    _money = NumberFormat.currency(
        locale: locale, symbol: symbol, decimalDigits: 0);
    _moneyCents = NumberFormat.currency(
        locale: locale, symbol: symbol, decimalDigits: 2);
    _compact = NumberFormat.compact(locale: locale);
  }

  static String get currencySymbol => _symbol;
  static String? get numberLocale => _locale;

  static NumberFormat _money =
      NumberFormat.currency(symbol: r'$', decimalDigits: 0);
  static NumberFormat _moneyCents =
      NumberFormat.currency(symbol: r'$', decimalDigits: 2);
  static NumberFormat _compact = NumberFormat.compact();
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _fullDate = DateFormat('MMM d, yyyy');

  /// Whole units — for headline figures where the cents are noise.
  /// Use [moneyExact] anywhere a number is compared against another
  /// number the user can see.
  static String money(num value) => _money.format(value);

  /// Two decimals — transactions, balances, targets, and any flag
  /// message that states a number against a threshold.
  static String moneyCents(num value) => _moneyCents.format(value);

  /// Two decimals unless the value is a whole unit, in which case the
  /// cents are dropped. Keeps headlines clean without ever printing
  /// "$0" for a non-zero amount.
  static String moneyExact(num value) =>
      value == value.truncateToDouble() ? _money.format(value) : _moneyCents.format(value);

  static String moneySigned(num value) =>
      value < 0 ? '-${moneyExact(value.abs())}' : moneyExact(value);

  static String compact(num value) => _compact.format(value);

  static String hours(double value) {
    final rounded = (value * 10).roundToDouble() / 10;
    return rounded == rounded.truncateToDouble()
        ? '${rounded.toInt()}h'
        : '${rounded.toStringAsFixed(1)}h';
  }

  static String number(double value, {int maxDecimals = 1}) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(maxDecimals);
  }

  static String percent(double fraction) =>
      '${(fraction * 100).clamp(0, 999).round()}%';

  static String shortDate(DateTime d) => _shortDate.format(d);

  static String fullDate(DateTime d) => _fullDate.format(d);

  static String timeOfDay(int hour, int minute) {
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat.jm().format(dt);
  }
}

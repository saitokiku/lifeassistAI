import 'package:intl/intl.dart';

/// Display formatting. Keep numbers large and unambiguous.
class Formatters {
  Formatters._();

  static final NumberFormat _money =
      NumberFormat.currency(symbol: r'$', decimalDigits: 0);
  static final NumberFormat _moneyCents =
      NumberFormat.currency(symbol: r'$', decimalDigits: 2);
  static final NumberFormat _compact = NumberFormat.compact();
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _fullDate = DateFormat('MMM d, yyyy');

  static String money(num value) => _money.format(value);

  static String moneyCents(num value) => _moneyCents.format(value);

  static String moneySigned(num value) =>
      value < 0 ? '-${_money.format(value.abs())}' : _money.format(value);

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

import 'package:intl/intl.dart';

/// Date helpers. Weeks start Monday. Dates are stored as `yyyy-MM-dd` keys.
///
/// **Day arithmetic uses calendar fields, never `Duration`.** A
/// `Duration` is exact elapsed time while a local `DateTime` is
/// wall-clock, so `subtract(Duration(days: n))` across a spring-forward
/// transition lands on the wrong calendar day — walking back from
/// 2025-03-12 in America/New_York used to skip 2025-03-09 entirely,
/// silently corrupting streaks and every trailing window. Use
/// [addDays]/[subtractDays] (or `DateTime(y, m, d ± n)`, which Dart
/// normalizes) for anything measured in days.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');

  static String dateKey(DateTime date) => _keyFormat.format(date);

  /// [date] plus [days] calendar days, at midnight local. DST-safe.
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  /// [date] minus [days] calendar days, at midnight local. DST-safe.
  static DateTime subtractDays(DateTime date, int days) =>
      addDays(date, -days);

  /// Whole calendar days from [from] to [to], sign-aware and DST-safe.
  /// `difference().inDays` truncates a 23- or 25-hour day to the wrong
  /// value; comparing UTC-normalized midnights does not.
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  static DateTime parseDateKey(String key) => DateTime.parse(key);

  /// Like [parseDateKey] but null on malformed input instead of throwing.
  static DateTime? tryParseDateKey(String key) => DateTime.tryParse(key);

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Monday 00:00 of the week containing [date].
  static DateTime startOfWeek(DateTime date) {
    final d = dateOnly(date);
    return subtractDays(d, d.weekday - DateTime.monday);
  }

  /// Sunday (last day) of the week containing [date], at 00:00.
  static DateTime endOfWeek(DateTime date) => addDays(startOfWeek(date), 6);

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  static int daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month, daysInMonth(date));

  static DateTime endOfYear(DateTime date) => DateTime(date.year, 12, 31);

  /// The seven date keys of the week containing [date], Monday..Sunday.
  static List<String> weekDateKeys(DateTime date) {
    final start = startOfWeek(date);
    return List.generate(7, (i) => dateKey(addDays(start, i)));
  }

  /// Last [count] date keys ending at [date], oldest first.
  static List<String> lastDateKeys(DateTime date, int count) {
    final d = dateOnly(date);
    return List.generate(count, (i) => dateKey(subtractDays(d, count - 1 - i)));
  }

  static bool isInWeek(String dateKeyValue, DateTime weekOf) {
    final d = parseDateKey(dateKeyValue);
    final start = startOfWeek(weekOf);
    final end = addDays(start, 7);
    return !d.isBefore(start) && d.isBefore(end);
  }

  static bool isInMonth(String dateKeyValue, DateTime monthOf) {
    final d = parseDateKey(dateKeyValue);
    return d.year == monthOf.year && d.month == monthOf.month;
  }

  /// Date the user turns [age], given their birthday. Null if birthday null.
  static DateTime? birthdayAtAge(DateTime? birthday, int age) {
    if (birthday == null) return null;
    return DateTime(birthday.year + age, birthday.month, birthday.day);
  }

  /// Whole days from [from] (date-only) until [target] (date-only).
  static int daysUntil(DateTime target, {DateTime? from}) =>
      daysBetween(from ?? DateTime.now(), target);

  /// Retirement-contribution deadline for the tax year containing [now]:
  /// April 15 of the following year (used by a legacy dynamic countdown).
  static DateTime retirementContributionDeadline(DateTime now) {
    final thisYearDeadline = DateTime(now.year, 4, 15);
    if (!dateOnly(now).isAfter(thisYearDeadline)) return thisYearDeadline;
    return DateTime(now.year + 1, 4, 15);
  }
}

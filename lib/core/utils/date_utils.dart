import 'package:intl/intl.dart';

/// Date helpers. Weeks start Monday. Dates are stored as `yyyy-MM-dd` keys.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');

  static String dateKey(DateTime date) => _keyFormat.format(date);

  static DateTime parseDateKey(String key) => DateTime.parse(key);

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Monday 00:00 of the week containing [date].
  static DateTime startOfWeek(DateTime date) {
    final d = dateOnly(date);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  /// Sunday (last day) of the week containing [date], at 00:00.
  static DateTime endOfWeek(DateTime date) =>
      startOfWeek(date).add(const Duration(days: 6));

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
    return List.generate(7, (i) => dateKey(start.add(Duration(days: i))));
  }

  /// Last [count] date keys ending at [date], oldest first.
  static List<String> lastDateKeys(DateTime date, int count) {
    final d = dateOnly(date);
    return List.generate(
      count,
      (i) => dateKey(d.subtract(Duration(days: count - 1 - i))),
    );
  }

  static bool isInWeek(String dateKeyValue, DateTime weekOf) {
    final d = parseDateKey(dateKeyValue);
    final start = startOfWeek(weekOf);
    final end = start.add(const Duration(days: 7));
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
  static int daysUntil(DateTime target, {DateTime? from}) {
    final a = dateOnly(from ?? DateTime.now());
    return dateOnly(target).difference(a).inDays;
  }

  /// Retirement-contribution deadline for the tax year containing [now]:
  /// April 15 of the following year (used by a legacy dynamic countdown).
  static DateTime retirementContributionDeadline(DateTime now) {
    final thisYearDeadline = DateTime(now.year, 4, 15);
    if (!dateOnly(now).isAfter(thisYearDeadline)) return thisYearDeadline;
    return DateTime(now.year + 1, 4, 15);
  }
}

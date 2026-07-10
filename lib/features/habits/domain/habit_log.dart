/// Habit log domain model plus streak math.
library;

export '../../../core/storage/app_database.dart' show HabitLog;

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/weekdays.dart';

class HabitStats {
  HabitStats._();

  /// Consecutive scheduled days logged, ending today (or the most recent
  /// scheduled day — an open day doesn't break the streak).
  ///
  /// Forgiveness over pressure, with rules that keep the number honest:
  /// - Days outside the habit's [weekdays] schedule are skipped entirely —
  ///   a Mon/Wed/Fri habit isn't "broken" by Tuesday.
  /// - One missed scheduled day per calendar week is forgiven (a grace
  ///   day). It doesn't add to the count; it just doesn't zero it.
  static int streak(
    Set<String> loggedDateKeys,
    DateTime today, {
    int weekdays = WeekdayMask.all,
    bool allowGraceDay = true,
  }) {
    var day = AppDateUtils.dateOnly(today);
    var streak = 0;
    var isToday = true;
    final graceWeeksUsed = <String>{};

    // Hard stop far beyond any plausible streak keeps this loop safe.
    for (var i = 0; i < 3660; i++) {
      final scheduled = WeekdayMask.isDueOn(weekdays, day);
      if (!scheduled) {
        day = day.subtract(const Duration(days: 1));
        isToday = false;
        continue;
      }
      final logged = loggedDateKeys.contains(AppDateUtils.dateKey(day));
      if (logged) {
        streak++;
      } else if (isToday) {
        // Today is still open — not logging yet doesn't break anything.
      } else if (allowGraceDay &&
          graceWeeksUsed.add(
              AppDateUtils.dateKey(AppDateUtils.startOfWeek(day)))) {
        // One forgiven miss this week; the streak survives, uncounted.
        // (A dead tail still ends at 0 — grace bridges runs, it can't
        // mint one from nothing.)
      } else {
        break;
      }
      day = day.subtract(const Duration(days: 1));
      isToday = false;
    }
    return streak;
  }

  /// Days logged in the week containing [today].
  static int weeklyCount(Set<String> loggedDateKeys, DateTime today) =>
      AppDateUtils.weekDateKeys(today).where(loggedDateKeys.contains).length;

  /// Scheduled days in the week containing [today] (for x/y week progress).
  static int scheduledCountThisWeek(int weekdays) =>
      WeekdayMask.countDays(weekdays);
}

/// Habit log domain model plus streak math.
library;

export '../../../core/storage/app_database.dart' show HabitLog;

import '../../../core/utils/date_utils.dart';

class HabitStats {
  HabitStats._();

  /// Consecutive days logged ending today (or yesterday when today isn't
  /// logged yet — an open day doesn't break the streak).
  static int streak(Set<String> loggedDateKeys, DateTime today) {
    var day = AppDateUtils.dateOnly(today);
    if (!loggedDateKeys.contains(AppDateUtils.dateKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (loggedDateKeys.contains(AppDateUtils.dateKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Days logged in the week containing [today].
  static int weeklyCount(Set<String> loggedDateKeys, DateTime today) =>
      AppDateUtils.weekDateKeys(today)
          .where(loggedDateKeys.contains)
          .length;
}

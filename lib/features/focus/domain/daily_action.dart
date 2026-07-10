/// Daily action domain model plus streak math.
///
/// One small, deliberate step toward the main goal per day, with an honest
/// note on how it went. Stored in the `daily_experiments` table (pre-v2
/// name); the drift-generated `DailyExperiment` class is re-exported here.
library;

export '../../../core/storage/app_database.dart' show DailyExperiment;
export 'action_verdict.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import 'action_verdict.dart';

extension DailyActionX on DailyExperiment {
  ActionVerdict get verdictEnum => ActionVerdict.parse(verdict);
}

class DailyActionStats {
  DailyActionStats._();

  /// Consecutive days with a logged action, ending today (or yesterday
  /// when today isn't logged yet — an open day doesn't break the streak).
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

  /// Days in the last [window] days (ending today) with no action logged.
  static int missedDays(Set<String> loggedDateKeys, DateTime today,
      {int window = 30}) {
    final keys = AppDateUtils.lastDateKeys(today, window);
    return keys.where((k) => !loggedDateKeys.contains(k)).length;
  }
}

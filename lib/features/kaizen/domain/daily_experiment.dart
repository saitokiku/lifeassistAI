/// Daily experiment domain model plus streak math.
library;

export '../../../core/storage/app_database.dart' show DailyExperiment;
export 'experiment_verdict.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import 'experiment_verdict.dart';

extension DailyExperimentX on DailyExperiment {
  ExperimentVerdict get verdictEnum => ExperimentVerdict.parse(verdict);
}

class ExperimentStats {
  ExperimentStats._();

  /// Consecutive days with a logged experiment, ending today (or yesterday
  /// when today has no verdict yet — an open day doesn't break the streak).
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

  /// Days in the last [window] days (ending today) with no experiment logged.
  static int missedDays(Set<String> loggedDateKeys, DateTime today,
      {int window = 30}) {
    final keys = AppDateUtils.lastDateKeys(today, window);
    return keys.where((k) => !loggedDateKeys.contains(k)).length;
  }
}

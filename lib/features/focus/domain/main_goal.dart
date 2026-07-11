/// Main goal domain model. The drift-generated data class is the single
/// source of truth; this file re-exports it and adds status + date helpers.
library;

export '../../../core/storage/app_database.dart' show MainGoal;

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Lifecycle of the main goal. One goal is active at a time; pausing keeps
/// it in place but relaxes the daily pressure, completing and archiving
/// retire it (history stays).
enum MainGoalStatus {
  active,
  paused,
  completed,
  archived;

  static MainGoalStatus parse(String raw) => switch (raw) {
        'paused' => MainGoalStatus.paused,
        'completed' => MainGoalStatus.completed,
        'archived' => MainGoalStatus.archived,
        _ => MainGoalStatus.active,
      };

  String get label => switch (this) {
        MainGoalStatus.active => 'Active',
        MainGoalStatus.paused => 'Paused',
        MainGoalStatus.completed => 'Completed',
        MainGoalStatus.archived => 'Archived',
      };
}

extension MainGoalX on MainGoal {
  MainGoalStatus get statusEnum => MainGoalStatus.parse(status);

  bool get isActive => statusEnum == MainGoalStatus.active;
  bool get isPaused => statusEnum == MainGoalStatus.paused;
  bool get isCompleted => statusEnum == MainGoalStatus.completed;

  DateTime? get targetDateTime =>
      targetDate == null ? null : AppDateUtils.parseDateKey(targetDate!);

  /// Whole days from [today] to the target date. Negative = past due.
  int? daysLeft(DateTime today) {
    final target = targetDateTime;
    if (target == null) return null;
    return target.difference(AppDateUtils.dateOnly(today)).inDays;
  }

  /// Days since the goal was created (age of the pursuit).
  int daysIn(DateTime today) => AppDateUtils.dateOnly(today)
      .difference(AppDateUtils.dateOnly(createdAt))
      .inDays;
}

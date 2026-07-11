/// Milestone domain model — the concrete steps under the main goal.
///
/// Stored in the `goals` table (its pre-v2 name, when these were
/// free-standing "goals"); the drift-generated `Goal` data class is the
/// single source of truth. This file re-exports it under the milestone
/// vocabulary and adds progress helpers.
library;

export '../../../core/storage/app_database.dart' show Goal;

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

extension MilestoneX on Goal {
  /// Progress toward the target value, clamped 0..1. Only meaningful for
  /// measurable milestones; checklist milestones use [isDone].
  double get progress =>
      targetValue <= 0 ? 0 : (currentValue / targetValue).clamp(0.0, 1.0);

  /// A milestone with a numeric target tracks a value; without one it's a
  /// simple check-off step.
  bool get isMeasurable => targetValue > 0;

  DateTime? get targetDateTime => targetDate == null || targetDate!.isEmpty
      ? null
      : AppDateUtils.parseDateKey(targetDate!);

  /// Whole days from [today] to the target date. Negative = past due.
  int? daysLeft(DateTime today) {
    final target = targetDateTime;
    if (target == null) return null;
    return target.difference(AppDateUtils.dateOnly(today)).inDays;
  }
}

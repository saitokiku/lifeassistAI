import '../../../core/storage/app_database.dart';
import 'time_category.dart';

export '../../../core/storage/app_database.dart' show TimeBudget;

/// One category's actual-vs-target for the current week.
class WeeklyTimeBudgetProgress {
  const WeeklyTimeBudgetProgress({
    required this.budget,
    required this.actualHours,
  });

  final TimeBudget budget;
  final double actualHours;

  TimeCategoryKind get kind => TimeCategoryKind.parse(budget.kind);

  double get targetHours => budget.weeklyTargetHours;

  double get remainingHours => targetHours - actualHours;

  /// Fraction of target reached; uncapped so over-target reads > 1.
  double get progress => targetHours <= 0
      ? (actualHours > 0 ? 1.0 : 0.0)
      : actualHours / targetHours;

  bool get isOverTarget => actualHours > targetHours && targetHours > 0;
}

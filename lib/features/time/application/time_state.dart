import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/countdown.dart';
import '../domain/time_category.dart';
import '../domain/weekly_time_budget.dart';

/// Display-ready time state for the current week.
class TimeState {
  factory TimeState.compute({
    required DateTime now,
    required List<TimeBudget> budgets,
    required List<TimeBlock> weekBlocks,
    required List<Countdown> countdowns,
    required DateTime? birthday,
  }) {
    final hoursByBudget = <String, double>{};
    final todayKey = AppDateUtils.dateKey(now);
    var hoursLoggedToday = 0.0;
    for (final block in weekBlocks) {
      hoursByBudget[block.budgetId] =
          (hoursByBudget[block.budgetId] ?? 0) + block.hours;
      if (block.date == todayKey) hoursLoggedToday += block.hours;
    }

    final progress = [
      for (final b in budgets)
        WeeklyTimeBudgetProgress(
          budget: b,
          actualHours: hoursByBudget[b.id] ?? 0,
        ),
    ];

    return TimeState._(
      now: now,
      budgets: budgets,
      weekBlocks: weekBlocks,
      progress: progress,
      hoursLoggedToday: hoursLoggedToday,
      countdowns: [
        for (final c in countdowns)
          ResolvedCountdown.resolve(c, now: now, birthday: birthday),
      ],
    );
  }

  const TimeState._({
    required this.now,
    required this.budgets,
    required this.weekBlocks,
    required this.progress,
    required this.hoursLoggedToday,
    required this.countdowns,
  });

  final DateTime now;
  final List<TimeBudget> budgets;
  final List<TimeBlock> weekBlocks;
  final List<WeeklyTimeBudgetProgress> progress;
  final double hoursLoggedToday;
  final List<ResolvedCountdown> countdowns;

  double hoursForKind(TimeCategoryKind kind) => progress
      .where((p) => p.kind == kind)
      .fold(0.0, (sum, p) => sum + p.actualHours);

  double targetForKind(TimeCategoryKind kind) => progress
      .where((p) => p.kind == kind)
      .fold(0.0, (sum, p) => sum + p.targetHours);

  double get kaizenHoursThisWeek => hoursForKind(TimeCategoryKind.kaizen);
  double get kaizenWeeklyTarget => targetForKind(TimeCategoryKind.kaizen);

  double get recoveryHoursThisWeek =>
      progress.where((p) => p.kind.countsAsRecovery).fold(
            0.0,
            (sum, p) => sum + p.actualHours,
          );

  double get recoveryWeeklyTarget =>
      progress.where((p) => p.kind.countsAsRecovery).fold(
            0.0,
            (sum, p) => sum + p.targetHours,
          );

  /// Hours logged today against exercise or meditation categories.
  double get healthHoursToday {
    final healthBudgetIds = budgets
        .where((b) => TimeCategoryKind.parse(b.kind).countsAsHealth)
        .map((b) => b.id)
        .toSet();
    final todayKey = AppDateUtils.dateKey(now);
    return weekBlocks
        .where((b) => b.date == todayKey && healthBudgetIds.contains(b.budgetId))
        .fold(0.0, (sum, b) => sum + b.hours);
  }

  /// The unlogged remainder of today. Available time is the real budget.
  double get availableHoursToday =>
      (24 - hoursLoggedToday).clamp(0.0, 24.0);

  double get totalTargetHours =>
      progress.fold(0.0, (sum, p) => sum + p.targetHours);

  double get totalActualHours =>
      progress.fold(0.0, (sum, p) => sum + p.actualHours);

  /// Weekly target hours not yet used, across all categories.
  double get remainingWeekHours =>
      (totalTargetHours - totalActualHours).clamp(0.0, double.infinity);

  List<WeeklyTimeBudgetProgress> get overTarget =>
      progress.where((p) => p.isOverTarget).toList();
}

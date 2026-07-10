import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../focus/application/focus_controller.dart';
import '../../focus/domain/main_goal.dart';
import '../../settings/application/settings_controller.dart';
import '../data/time_repository.dart';
import '../domain/time_category.dart';
import 'time_state.dart';

final timeRepositoryProvider = Provider<TimeRepository>(
  (ref) => TimeRepository(ref.watch(databaseProvider)),
);

final timeBudgetsProvider = StreamProvider<List<TimeBudget>>(
  (ref) => ref.watch(timeRepositoryProvider).watchBudgets(),
);

/// Blocks in the week containing "now"; rolls over with the clock.
final weekTimeBlocksProvider = StreamProvider<List<TimeBlock>>((ref) {
  final now = readToday(ref);
  return ref.watch(timeRepositoryProvider).watchWeekBlocks(now);
});

final recentTimeBlocksProvider = StreamProvider<List<TimeBlock>>(
  (ref) => ref.watch(timeRepositoryProvider).watchRecentBlocks(),
);

final countdownsProvider = StreamProvider<List<Countdown>>(
  (ref) => ref.watch(timeRepositoryProvider).watchCountdowns(),
);

/// Synthetic countdown key for the main goal's target date. Not a stored
/// row — injected at read time so the deadline the user actually committed
/// to is always on the clock.
const String goalTargetCountdownKey = 'goalTarget';

/// Combined time view state; null while sources are loading.
final timeStateProvider = Provider<TimeState?>((ref) {
  final now = readToday(ref);
  final budgets = ref.watch(timeBudgetsProvider).valueOrNull;
  final blocks = ref.watch(weekTimeBlocksProvider).valueOrNull;
  final countdowns = ref.watch(countdownsProvider).valueOrNull;
  final settings = ref.watch(settingsProvider).valueOrNull;
  final goal = ref.watch(mainGoalProvider).valueOrNull;
  if (budgets == null || blocks == null || countdowns == null) return null;

  final withGoal = [
    if (goal != null && goal.isActive && goal.targetDate != null)
      Countdown(
        id: 'goal-target',
        title: goal.title,
        targetDate: goal.targetDate,
        dynamicKey: goalTargetCountdownKey,
        sortOrder: -1,
      ),
    ...countdowns,
  ];

  return TimeState.compute(
    now: now,
    budgets: budgets,
    weekBlocks: blocks,
    countdowns: withGoal,
    birthday: settings?.birthday,
  );
});

/// One week's logged-hours totals for the history chart.
class WeeklyHoursPoint {
  const WeeklyHoursPoint({
    required this.weekStart,
    required this.totalHours,
    required this.goalHours,
  });

  final DateTime weekStart;
  final double totalHours;
  final double goalHours;
}

/// How many weeks of history the time chart shows.
const int kWeeklyHistoryWeeks = 8;

/// autoDispose: the `since` argument advances as weeks roll over, so old
/// instances must release their drift subscriptions instead of leaking.
final _blocksSinceProvider = StreamProvider.autoDispose
    .family<List<TimeBlock>, DateTime>((ref, since) {
  return ref.watch(timeRepositoryProvider).watchBlocksSince(since);
});

/// Last [kWeeklyHistoryWeeks] weeks of total vs main-goal hours (oldest first).
/// Null while sources load.
final weeklyHoursHistoryProvider = Provider<List<WeeklyHoursPoint>?>((ref) {
  final now = readToday(ref);
  final budgets = ref.watch(timeBudgetsProvider).valueOrNull;
  final firstWeekStart = AppDateUtils.startOfWeek(now)
      .subtract(const Duration(days: 7 * (kWeeklyHistoryWeeks - 1)));
  final blocks = ref.watch(_blocksSinceProvider(firstWeekStart)).valueOrNull;
  if (budgets == null || blocks == null) return null;

  final goalBudgetIds = budgets
      .where((b) => TimeCategoryKind.parse(b.kind) == TimeCategoryKind.goal)
      .map((b) => b.id)
      .toSet();

  final totals = <String, double>{};
  final goalHours = <String, double>{};
  for (final block in blocks) {
    final weekKey = AppDateUtils.dateKey(
        AppDateUtils.startOfWeek(AppDateUtils.parseDateKey(block.date)));
    totals[weekKey] = (totals[weekKey] ?? 0) + block.hours;
    if (goalBudgetIds.contains(block.budgetId)) {
      goalHours[weekKey] = (goalHours[weekKey] ?? 0) + block.hours;
    }
  }

  return [
    for (var i = 0; i < kWeeklyHistoryWeeks; i++)
      () {
        final weekStart = firstWeekStart.add(Duration(days: 7 * i));
        final key = AppDateUtils.dateKey(weekStart);
        return WeeklyHoursPoint(
          weekStart: weekStart,
          totalHours: totals[key] ?? 0,
          goalHours: goalHours[key] ?? 0,
        );
      }(),
  ];
});

class TimeController {
  TimeController(this._repo);

  final TimeRepository _repo;

  Future<void> createBudget({
    required String name,
    required String kind,
    required double weeklyTargetHours,
  }) =>
      _repo.createBudget(
          name: name, kind: kind, weeklyTargetHours: weeklyTargetHours);

  Future<void> updateBudget(TimeBudget budget) => _repo.updateBudget(budget);

  Future<void> deleteBudget(String id) => _repo.deleteBudget(id);

  Future<void> logBlock({
    required String budgetId,
    required DateTime date,
    required double hours,
    String? note,
  }) =>
      _repo.logBlock(budgetId: budgetId, date: date, hours: hours, note: note);

  Future<void> updateBlock(TimeBlock block) => _repo.updateBlock(block);

  Future<void> deleteBlock(String id) => _repo.deleteBlock(id);

  Future<void> createCountdown({
    required String title,
    required DateTime targetDate,
  }) =>
      _repo.createCountdown(title: title, targetDate: targetDate);

  Future<void> updateCountdown(Countdown countdown) =>
      _repo.updateCountdown(countdown);

  Future<void> deleteCountdown(String id) => _repo.deleteCountdown(id);
}

final timeControllerProvider = Provider<TimeController>(
  (ref) => TimeController(ref.watch(timeRepositoryProvider)),
);

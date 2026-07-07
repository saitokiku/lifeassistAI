import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../settings/application/settings_controller.dart';
import '../data/time_repository.dart';
import 'time_state.dart';

final timeRepositoryProvider = Provider<TimeRepository>(
  (ref) => TimeRepository(ref.watch(databaseProvider)),
);

final timeBudgetsProvider = StreamProvider<List<TimeBudget>>(
  (ref) => ref.watch(timeRepositoryProvider).watchBudgets(),
);

/// Blocks in the week containing "now"; rolls over with the clock.
final weekTimeBlocksProvider = StreamProvider<List<TimeBlock>>((ref) {
  final now = readNow(ref);
  return ref.watch(timeRepositoryProvider).watchWeekBlocks(now);
});

final recentTimeBlocksProvider = StreamProvider<List<TimeBlock>>(
  (ref) => ref.watch(timeRepositoryProvider).watchRecentBlocks(),
);

final countdownsProvider = StreamProvider<List<Countdown>>(
  (ref) => ref.watch(timeRepositoryProvider).watchCountdowns(),
);

/// Combined time view state; null while sources are loading.
final timeStateProvider = Provider<TimeState?>((ref) {
  final now = readNow(ref);
  final budgets = ref.watch(timeBudgetsProvider).valueOrNull;
  final blocks = ref.watch(weekTimeBlocksProvider).valueOrNull;
  final countdowns = ref.watch(countdownsProvider).valueOrNull;
  final settings = ref.watch(settingsProvider).valueOrNull;
  if (budgets == null || blocks == null || countdowns == null) return null;

  return TimeState.compute(
    now: now,
    budgets: budgets,
    weekBlocks: blocks,
    countdowns: countdowns,
    birthday: settings?.birthday,
  );
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

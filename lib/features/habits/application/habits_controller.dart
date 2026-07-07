import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../data/habits_repository.dart';
import 'habits_state.dart';

final habitsRepositoryProvider = Provider<HabitsRepository>(
  (ref) => HabitsRepository(ref.watch(databaseProvider)),
);

final habitsProvider = StreamProvider<List<Habit>>(
  (ref) => ref.watch(habitsRepositoryProvider).watchHabits(),
);

final habitLogsProvider = StreamProvider<List<HabitLog>>(
  (ref) => ref.watch(habitsRepositoryProvider).watchAllLogs(),
);

/// Combined habits view state; null while loading.
final habitsStateProvider = Provider<HabitsState?>((ref) {
  final now = readNow(ref);
  final habits = ref.watch(habitsProvider).valueOrNull;
  final logs = ref.watch(habitLogsProvider).valueOrNull;
  if (habits == null || logs == null) return null;

  final today = AppDateUtils.dateOnly(now);
  final logsByHabit = <String, List<HabitLog>>{};
  for (final log in logs) {
    logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
  }

  return HabitsState(
    today: today,
    habits: [
      for (final h in habits)
        HabitView(habit: h, logs: logsByHabit[h.id] ?? const [], today: today),
    ],
  );
});

class HabitsController {
  HabitsController(this._repo);

  final HabitsRepository _repo;

  Future<void> createHabit({
    required String name,
    required String type,
    String? unit,
  }) =>
      _repo.createHabit(name: name, type: type, unit: unit);

  Future<void> updateHabit(Habit habit) => _repo.updateHabit(habit);

  Future<void> deleteHabit(String id) => _repo.deleteHabit(id);

  Future<void> logHabit({
    required String habitId,
    required DateTime date,
    required double value,
    String? note,
  }) =>
      _repo.upsertLog(habitId: habitId, date: date, value: value, note: note);

  Future<void> unlogHabit({required String habitId, required DateTime date}) =>
      _repo.removeLog(habitId: habitId, date: date);
}

final habitsControllerProvider = Provider<HabitsController>(
  (ref) => HabitsController(ref.watch(habitsRepositoryProvider)),
);

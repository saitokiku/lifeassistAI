import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/habit_reminder_scheduler.dart';
import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../settings/application/settings_controller.dart';
import '../data/habits_repository.dart';
import 'habits_state.dart';

final habitsRepositoryProvider = Provider<HabitsRepository>(
  (ref) => HabitsRepository(ref.watch(databaseProvider)),
);

final habitsProvider = StreamProvider<List<Habit>>(
  (ref) => ref.watch(habitsRepositoryProvider).watchHabits(),
);

final habitLogsProvider = StreamProvider<List<HabitLog>>((ref) {
  final today = readToday(ref);
  return ref.watch(habitsRepositoryProvider).watchRecentLogs(today: today);
});

/// Combined habits view state; null while loading.
final habitsStateProvider = Provider<HabitsState?>((ref) {
  final now = readToday(ref);
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
  HabitsController(this._ref);

  final Ref _ref;

  HabitsRepository get _repo => _ref.read(habitsRepositoryProvider);

  /// Habit mutations resync per-habit reminders so the OS schedule always
  /// mirrors the table. No-op when notifications are off.
  Future<void> _resyncReminders() async {
    final habits = await _repo.getHabits();
    await _ref.read(habitReminderSchedulerProvider).syncAll(
          habits,
          appEnabled: _ref.read(notificationsEnabledProvider),
        );
  }

  Future<void> createHabit({
    required String name,
    required String type,
    String? unit,
    int weekdays = 127,
    int? reminderHour,
    int? reminderMinute,
    String? healthMetric,
    double? healthTarget,
  }) async {
    await _repo.createHabit(
      name: name,
      type: type,
      unit: unit,
      weekdays: weekdays,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      healthMetric: healthMetric,
      healthTarget: healthTarget,
    );
    await _resyncReminders();
  }

  Future<void> updateHabit(Habit habit) async {
    await _repo.updateHabit(habit);
    await _resyncReminders();
  }

  Future<void> deleteHabit(String id) async {
    final habit =
        (await _repo.getHabits()).where((h) => h.id == id).firstOrNull;
    await _repo.deleteHabit(id);
    if (habit != null) {
      await _ref
          .read(notificationServiceProvider)
          .cancelMany(HabitReminderScheduler.allIdsFor(habit));
    }
  }

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
  (ref) => HabitsController(ref),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../../../core/notifications/habit_reminder_scheduler.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../habits/application/habits_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../data/reminders_repository.dart';
import 'reminders_state.dart';

final remindersRepositoryProvider = Provider<RemindersRepository>(
  (ref) => RemindersRepository(ref.watch(databaseProvider)),
);

final remindersProvider = StreamProvider<List<Reminder>>(
  (ref) => ref.watch(remindersRepositoryProvider).watchReminders(),
);

final remindersStateProvider = Provider<RemindersState?>((ref) {
  final reminders = ref.watch(remindersProvider).valueOrNull;
  if (reminders == null) return null;
  return RemindersState(
    reminders: reminders,
    appNotificationsEnabled: ref.watch(notificationsEnabledProvider),
    platformSupported: ref.watch(notificationServiceProvider).isSupported,
  );
});

/// Mutations resync the OS schedule after every change so the reminders
/// table stays the single source of truth. Every mutation returns the
/// resync [Result] — callers surface failures instead of letting a nudge
/// silently never fire.
class RemindersController {
  RemindersController(this._ref);

  final Ref _ref;

  RemindersRepository get _repo => _ref.read(remindersRepositoryProvider);

  Future<Result<int>> _resync() async {
    // One-shots whose date has passed are done; disable the rows so they
    // don't linger as armed-looking reminders.
    await _repo.disableExpiredOneShots(
        todayKey: AppDateUtils.dateKey(DateTime.now()));
    final reminders = await _repo.getReminders();
    return _ref.read(reminderSchedulerProvider).syncAll(
          reminders,
          appEnabled: _ref.read(notificationsEnabledProvider),
        );
  }

  /// Reconciles the OS schedule with the table right now — used after
  /// the Siri capture queue drains reminder rows written by Swift.
  Future<Result<int>> resyncNow() => _resync();

  Future<Result<int>> createReminder({
    required String title,
    required String message,
    required String type,
    required int hour,
    required int minute,
    int weekdays = 127,
    String? oneShotDate,
  }) async {
    await _repo.createReminder(
      title: title,
      message: message,
      type: type,
      hour: hour,
      minute: minute,
      weekdays: weekdays,
      oneShotDate: oneShotDate,
    );
    return _resync();
  }

  Future<Result<int>> updateReminder(Reminder reminder) async {
    await _repo.updateReminder(reminder);
    return _resync();
  }

  Future<Result<int>> setEnabled(String id, bool enabled) async {
    await _repo.setEnabled(id, enabled);
    return _resync();
  }

  Future<Result<int>> deleteReminder(String id) async {
    final reminder =
        (await _repo.getReminders()).where((r) => r.id == id).firstOrNull;
    await _repo.deleteReminder(id);
    if (reminder != null) {
      await _ref
          .read(notificationServiceProvider)
          .cancelMany(ReminderScheduler.allIdsFor(reminder));
    }
    return _resync();
  }

  /// Requests OS permission, stores the app-level toggle, and syncs both
  /// reminder spaces (standalone reminders + per-habit nudges).
  /// Returns whether notifications ended up enabled.
  Future<bool> enableNotifications() async {
    final granted =
        await _ref.read(notificationServiceProvider).requestPermission();
    await _ref
        .read(settingsControllerProvider)
        .setNotificationsEnabled(granted);
    if (granted) {
      await _resync();
      final habits = await _ref.read(habitsRepositoryProvider).getHabits();
      await _ref
          .read(habitReminderSchedulerProvider)
          .syncAll(habits, appEnabled: true);
    }
    return granted;
  }

  Future<void> disableNotifications() async {
    await _ref.read(settingsControllerProvider).setNotificationsEnabled(false);
    // Cancel only ids this app's subsystems own — reminders and habits.
    final reminders = await _repo.getReminders();
    final habits = await _ref.read(habitsRepositoryProvider).getHabits();
    await _ref.read(notificationServiceProvider).cancelMany([
      for (final r in reminders) ...ReminderScheduler.allIdsFor(r),
      for (final h in habits) ...HabitReminderScheduler.allIdsFor(h),
    ]);
  }
}

final remindersControllerProvider =
    Provider<RemindersController>((ref) => RemindersController(ref));

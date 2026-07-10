import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
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
/// table stays the single source of truth.
class RemindersController {
  RemindersController(this._ref);

  final Ref _ref;

  RemindersRepository get _repo => _ref.read(remindersRepositoryProvider);

  Future<Result<int>> _resync() async {
    final reminders = await _repo.getReminders();
    return _ref.read(reminderSchedulerProvider).syncAll(
          reminders,
          appEnabled: _ref.read(notificationsEnabledProvider),
        );
  }

  Future<void> createReminder({
    required String title,
    required String message,
    required String type,
    required int hour,
    required int minute,
  }) async {
    await _repo.createReminder(
      title: title,
      message: message,
      type: type,
      hour: hour,
      minute: minute,
    );
    await _resync();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _repo.updateReminder(reminder);
    await _resync();
  }

  Future<void> setEnabled(String id, bool enabled) async {
    await _repo.setEnabled(id, enabled);
    await _resync();
  }

  Future<void> deleteReminder(String id) async {
    final reminder =
        (await _repo.getReminders()).where((r) => r.id == id).firstOrNull;
    await _repo.deleteReminder(id);
    if (reminder != null) {
      await _ref
          .read(notificationServiceProvider)
          .cancel(reminder.notificationId);
    }
    await _resync();
  }

  /// Requests OS permission, stores the app-level toggle, and syncs.
  /// Returns whether notifications ended up enabled.
  Future<bool> enableNotifications() async {
    final granted =
        await _ref.read(notificationServiceProvider).requestPermission();
    await _ref
        .read(settingsControllerProvider)
        .setNotificationsEnabled(granted);
    if (granted) await _resync();
    return granted;
  }

  Future<void> disableNotifications() async {
    await _ref.read(settingsControllerProvider).setNotificationsEnabled(false);
    await _ref.read(notificationServiceProvider).cancelAll();
  }
}

final remindersControllerProvider =
    Provider<RemindersController>((ref) => RemindersController(ref));

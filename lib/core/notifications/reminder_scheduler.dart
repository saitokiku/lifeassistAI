import '../errors/result.dart';
import '../storage/app_database.dart';
import 'notification_service.dart';
import 'reminder_message_builder.dart';

/// Keeps OS-scheduled notifications in sync with the reminders table.
/// Call [syncAll] after any reminder mutation or settings change.
class ReminderScheduler {
  ReminderScheduler(this._notifications);

  final NotificationService _notifications;

  bool get isSupported => _notifications.isSupported;

  /// Cancels everything and reschedules enabled reminders.
  /// When [appEnabled] is false (user toggle or permission denied), all
  /// scheduled notifications are simply cancelled.
  Future<Result<int>> syncAll(
    List<Reminder> reminders, {
    required bool appEnabled,
  }) async {
    if (!_notifications.isSupported) {
      return const Result.failure('Notifications are not supported on web.');
    }
    await _notifications.cancelAll();
    if (!appEnabled) return const Result.success(0);

    var scheduled = 0;
    for (final reminder in reminders.where((r) => r.enabled)) {
      final result = await _notifications.scheduleDaily(
        id: reminder.notificationId,
        title: reminder.title,
        body: ReminderMessageBuilder.bodyFor(reminder),
        hour: reminder.hour,
        minute: reminder.minute,
      );
      if (result.isSuccess) scheduled++;
    }
    return Result.success(scheduled);
  }
}

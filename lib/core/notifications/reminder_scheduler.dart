import '../errors/result.dart';
import '../storage/app_database.dart';
import '../utils/date_utils.dart';
import 'notification_service.dart';
import 'reminder_message_builder.dart';

/// Keeps OS-scheduled notifications in sync with the reminders table.
/// Call [syncAll] after any reminder mutation or settings change.
///
/// Cancellation is per-id, never [NotificationService.cancelAll] — other
/// subsystems (per-habit reminders, Siri-armed one-shots) own their own id
/// spaces and must survive a reminders resync.
class ReminderScheduler {
  ReminderScheduler(this._notifications);

  final NotificationService _notifications;

  bool get isSupported => _notifications.isSupported;

  /// Spacing between per-weekday variants of one reminder's id. Large
  /// enough that two reminders' variant sets colliding is as unlikely as
  /// their base hashes colliding.
  static const int _weekdayIdStep = 0x01000000;

  /// Every notification id a reminder may occupy: the base id (daily and
  /// one-shot schedules) plus one variant per weekday (weekly schedules).
  static Iterable<int> allIdsFor(Reminder reminder) sync* {
    yield reminder.notificationId;
    for (var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++) {
      yield weekdayIdFor(reminder.notificationId, weekday);
    }
  }

  static int weekdayIdFor(int baseId, int weekday) =>
      (baseId + weekday * _weekdayIdStep) & 0x7fffffff;

  /// Reconciles the OS schedule with [reminders]: cancels every id these
  /// reminders may hold, then reschedules the enabled ones. When
  /// [appEnabled] is false (user toggle off or permission denied) it stops
  /// after the cancellation pass.
  ///
  /// Returns the number of reminders scheduled, or the first scheduling
  /// error — callers surface failures instead of pretending the nudge is
  /// armed when it isn't.
  Future<Result<int>> syncAll(
    List<Reminder> reminders, {
    required bool appEnabled,
  }) async {
    if (!_notifications.isSupported) {
      return const Result.failure('Notifications are not supported on web.');
    }
    await _notifications
        .cancelMany([for (final r in reminders) ...allIdsFor(r)]);
    if (!appEnabled) return const Result.success(0);

    var scheduled = 0;
    String? firstError;
    for (final reminder in reminders.where((r) => r.enabled)) {
      final result = await _scheduleOne(reminder);
      switch (result) {
        case Success():
          scheduled++;
        case Failure(:final message):
          firstError ??= '${reminder.title}: $message';
      }
    }
    if (firstError != null) return Result.failure(firstError);
    return Result.success(scheduled);
  }

  /// Where a tap on this reminder's notification lands. The daily step
  /// opens the capture sheet itself — the nudge IS the input.
  static String payloadFor(Reminder reminder) => switch (reminder.type) {
        'dailyAction' => 'lifeassist://capture?type=step',
        'moneyCheck' => 'route:/money',
        'morningCommand' || 'nightReview' => 'route:/today',
        _ => 'route:/reminders',
      };

  Future<Result<void>> _scheduleOne(Reminder reminder) async {
    final body = ReminderMessageBuilder.bodyFor(reminder);
    final payload = payloadFor(reminder);

    // One-shot: fire once on its date; expired dates are the repository's
    // job to disable (see RemindersRepository.disableExpiredOneShots).
    final oneShot = reminder.oneShotDate;
    if (oneShot != null && oneShot.isNotEmpty) {
      final date = AppDateUtils.tryParseDateKey(oneShot);
      if (date == null) {
        return const Result.failure('The date could not be read.');
      }
      return _notifications.scheduleOnce(
        id: reminder.notificationId,
        title: reminder.title,
        body: body,
        when: DateTime(
            date.year, date.month, date.day, reminder.hour, reminder.minute),
        payload: payload,
      );
    }

    // Daily (all weekdays selected) uses the single base id.
    if (reminder.weekdays >= 127 || reminder.weekdays <= 0) {
      return _notifications.scheduleDaily(
        id: reminder.notificationId,
        title: reminder.title,
        body: body,
        hour: reminder.hour,
        minute: reminder.minute,
        payload: payload,
      );
    }

    // Weekly: one schedule per selected weekday, each on its variant id.
    Result<void>? firstFailure;
    for (var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++) {
      if (reminder.weekdays & (1 << (weekday - DateTime.monday)) == 0) {
        continue;
      }
      final result = await _notifications.scheduleWeekly(
        id: weekdayIdFor(reminder.notificationId, weekday),
        title: reminder.title,
        body: body,
        weekday: weekday,
        hour: reminder.hour,
        minute: reminder.minute,
        payload: payload,
      );
      if (result case Failure(:final message)) {
        firstFailure ??= Result.failure(message);
      }
    }
    return firstFailure ?? const Result.success(null);
  }
}

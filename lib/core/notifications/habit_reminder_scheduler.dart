import '../storage/app_database.dart';
import 'notification_ids.dart';
import 'notification_service.dart';

/// Keeps per-habit reminder notifications in sync with the habits table.
///
/// Each habit owns one aligned block of notification ids (see
/// [NotificationIds]), allocated once and stored on the row — so a
/// reminders resync can never touch a habit's ids and vice versa. This
/// used to be a `String.hashCode` derivation, which is not stable
/// across platforms or SDK versions and shared one flat range with
/// reminders. A habit gets a nudge only when it has a reminder time,
/// isn't archived, and today is on its weekday schedule.
class HabitReminderScheduler {
  HabitReminderScheduler(this._notifications);

  final NotificationService _notifications;

  bool get isSupported => _notifications.isSupported;

  /// The habit's stored base id. 0 means the row predates assignment
  /// (only reachable if a write raced the migration); such a habit has
  /// no notifications to cancel or arm.
  static int notificationIdFor(Habit habit) => habit.notificationId;

  /// Every id a habit may occupy (base + weekday variants).
  static Iterable<int> allIdsFor(Habit habit) =>
      habit.notificationId == 0
          ? const []
          : NotificationIds.blockFor(habit.notificationId);

  /// Cancels all habit-owned ids, then arms reminders for the eligible
  /// habits. Failures are quietly tolerated per-habit — the habit list
  /// itself stays the source of truth and the next sync retries.
  Future<int> syncAll(List<Habit> habits, {required bool appEnabled}) async {
    if (!_notifications.isSupported) return 0;
    await _notifications
        .cancelMany([for (final h in habits) ...allIdsFor(h)]);
    if (!appEnabled) return 0;

    var scheduled = 0;
    for (final habit in habits) {
      if (habit.isArchived) continue;
      final hour = habit.reminderHour;
      final minute = habit.reminderMinute;
      if (hour == null || minute == null) continue;

      final base = habit.notificationId;
      if (base == 0) continue; // no id assigned; nothing to arm
      const body = 'A small daily support. Check it off when done.';
      if (habit.weekdays & 127 == 127 || habit.weekdays & 127 == 0) {
        final result = await _notifications.scheduleDaily(
          id: base,
          title: habit.name,
          body: body,
          hour: hour,
          minute: minute,
          payload: 'route:/habits',
        );
        if (result.isSuccess) scheduled++;
        continue;
      }
      var any = false;
      for (var weekday = DateTime.monday;
          weekday <= DateTime.sunday;
          weekday++) {
        if (habit.weekdays & (1 << (weekday - DateTime.monday)) == 0) {
          continue;
        }
        final result = await _notifications.scheduleWeekly(
          id: NotificationIds.weekdayId(base, weekday),
          title: habit.name,
          body: body,
          weekday: weekday,
          hour: hour,
          minute: minute,
          payload: 'route:/habits',
        );
        any = any || result.isSuccess;
      }
      if (any) scheduled++;
    }
    return scheduled;
  }
}

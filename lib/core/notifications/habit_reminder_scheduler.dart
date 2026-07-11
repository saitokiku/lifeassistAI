import '../storage/app_database.dart';
import 'notification_service.dart';
import 'reminder_scheduler.dart';

/// Keeps per-habit reminder notifications in sync with the habits table.
///
/// Habits occupy their own notification-id space (namespaced hash), so a
/// reminders resync never touches them and vice versa. A habit gets a
/// nudge only when it has a reminder time, isn't archived, and today is
/// on its weekday schedule.
class HabitReminderScheduler {
  HabitReminderScheduler(this._notifications);

  final NotificationService _notifications;

  bool get isSupported => _notifications.isSupported;

  /// Stable id, namespaced away from the reminders id space.
  static int notificationIdFor(String habitId) =>
      'habit:$habitId'.hashCode & 0x7fffffff;

  /// Every id a habit may occupy (base + weekday variants).
  static Iterable<int> allIdsFor(Habit habit) sync* {
    final base = notificationIdFor(habit.id);
    yield base;
    for (var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++) {
      yield ReminderScheduler.weekdayIdFor(base, weekday);
    }
  }

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

      final base = notificationIdFor(habit.id);
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
          id: ReminderScheduler.weekdayIdFor(base, weekday),
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

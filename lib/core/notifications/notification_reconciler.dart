import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../storage/app_database.dart';
import '../storage/preferences_service.dart';
import '../utils/date_utils.dart';
import 'habit_reminder_scheduler.dart';
import 'notification_service.dart';
import 'reminder_scheduler.dart';

/// Result of one reconciliation pass.
class ReconcileResult {
  const ReconcileResult({
    this.ran = false,
    this.reminders = 0,
    this.habits = 0,
    this.pending = 0,
    this.overBudget = false,
    this.permissionLost = false,
  });

  final bool ran;
  final int reminders;
  final int habits;

  /// Pending OS notifications after the pass.
  final int pending;

  /// True when the schedule exceeds what the OS will hold, so some
  /// nudges silently won't fire.
  final bool overBudget;

  /// True when the app believed notifications were on but the OS has
  /// since revoked permission.
  final bool permissionLost;
}

/// Re-arms OS notification schedules from the database.
///
/// Three problems this fixes, all of which produced nudges the user
/// believed in and the system never delivered:
///
/// * **Nothing re-armed on a plain launch.** `syncAll` ran only when a
///   Siri capture reported reminder changes, so a timezone change, a
///   DST shift, an OS restore, or a permission revoke-and-restore left
///   stale or absent schedules indefinitely.
/// * **Permission was never re-checked.** The app stored the grant
///   result at request time and trusted it forever.
/// * **iOS caps pending notifications at 64** and silently drops the
///   rest. Nothing counted them, so a user with many weekday-scheduled
///   habits lost nudges with no signal.
class NotificationReconciler {
  NotificationReconciler({
    required AppDatabase database,
    required PreferencesService preferences,
    required NotificationService notifications,
  })  : _db = database,
        _prefs = preferences,
        _notifications = notifications;

  final AppDatabase _db;
  final PreferencesService _prefs;
  final NotificationService _notifications;

  /// iOS keeps only the 64 soonest pending notifications.
  static const int pendingBudget = 64;

  /// Reconciles at most once per calendar day unless [force].
  Future<ReconcileResult> reconcile({DateTime? now, bool force = false}) async {
    if (!_notifications.isSupported) return const ReconcileResult();
    final today = AppDateUtils.dateKey(now ?? DateTime.now());

    // A scheme bump means ids armed under the old layout can no longer
    // be addressed; clear the board once, then re-arm from the rows.
    final schemeChanged =
        _prefs.notificationIdScheme != AppConstants.notificationIdScheme;
    if (!force && !schemeChanged && _prefs.remindersArmedOn == today) {
      return const ReconcileResult();
    }

    if (!_prefs.notificationsEnabled) {
      await _prefs.setRemindersArmedOn(today);
      return const ReconcileResult(ran: true);
    }

    // Trust the OS, not our own stored answer.
    final permitted = await _notifications.hasPermission();
    if (!permitted) {
      return const ReconcileResult(ran: true, permissionLost: true);
    }

    if (schemeChanged) {
      await _notifications.cancelAll();
      await _prefs.setNotificationIdScheme(AppConstants.notificationIdScheme);
    }

    final reminders = await _db.select(_db.reminders).get();
    final habits = await _db.select(_db.habits).get();

    final reminderResult = await ReminderScheduler(_notifications)
        .syncAll(reminders, appEnabled: true);
    final habitCount = await HabitReminderScheduler(_notifications)
        .syncAll(habits, appEnabled: true);

    final pending = await _notifications.pendingCount();
    await _prefs.setRemindersArmedOn(today);

    if (kDebugMode && pending > pendingBudget) {
      debugPrint('Notification budget exceeded: $pending > $pendingBudget');
    }

    return ReconcileResult(
      ran: true,
      reminders: reminderResult.valueOrNull ?? 0,
      habits: habitCount,
      pending: pending,
      overBudget: pending > pendingBudget,
    );
  }
}

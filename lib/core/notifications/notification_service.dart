import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../errors/result.dart';
import 'notification_ids.dart';

/// Wraps flutter_local_notifications behind a platform-safe API.
///
/// Web has no local notification scheduling: [isSupported] is false there
/// and every method becomes a graceful no-op, so callers never branch on
/// platform themselves.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Invoked with the notification payload when the user taps one.
  void Function(String payload)? onTap;

  static const Duration snoozeDuration = Duration(minutes: 30);
  static const String snoozeActionId = 'snooze';

  /// Local scheduling is unavailable on web.
  bool get isSupported => !kIsWeb;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    tz_data.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      // Keep the default (UTC). Reminders still fire, times may be offset;
      // the reminder screen surfaces the device timezone for sanity checks.
    }

    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'reminder',
          actions: [
            DarwinNotificationAction.plain(snoozeActionId, 'Snooze 30 min'),
          ],
        ),
      ],
    );
    final initSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleResponse,
    );
    _initialized = true;
  }

  Future<void> _handleResponse(NotificationResponse response) async {
    if (response.actionId == snoozeActionId) {
      final id = response.id;
      if (id != null) {
        await _plugin.zonedSchedule(
          NotificationIds.snoozeFor(id),
          'Reminder',
          'You snoozed this — time to take another look.',
          tz.TZDateTime.now(tz.local).add(snoozeDuration),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: response.payload,
        );
      }
      return;
    }
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) onTap?.call(payload);
  }

  /// The payload of the notification that cold-started the app, if any.
  Future<String?> launchPayload() async {
    if (!isSupported) return null;
    await initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  /// Whether the OS currently permits notifications — asked fresh, not
  /// remembered. A grant recorded at request time says nothing about
  /// today: the user may have revoked it in system settings, and the
  /// app would keep reporting reminders as armed. Platforms without a
  /// permission concept report true.
  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    await initialize();
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return (await ios.checkPermissions())?.isEnabled ?? false;
      }
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macos != null) {
        return (await macos.checkPermissions())?.isEnabled ?? false;
      }
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
    } catch (_) {
      // Plugin can't answer — don't strand the user's reminders on a
      // failed query; assume permitted and let scheduling report.
    }
    return true;
  }

  /// How many notifications the OS currently holds for this app.
  Future<int> pendingCount() async {
    if (!isSupported) return 0;
    await initialize();
    try {
      return (await _plugin.pendingNotificationRequests()).length;
    } catch (_) {
      return 0;
    }
  }

  /// Asks the OS for notification permission. Returns whether granted.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await initialize();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      final granted =
          await macos.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    // Other desktop platforms: no runtime permission concept.
    return true;
  }

  static const _channel = AndroidNotificationDetails(
    'life_dashboard_reminders',
    'Reminders',
    channelDescription: 'Daily reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    actions: [
      AndroidNotificationAction(snoozeActionId, 'Snooze 30 min'),
    ],
  );

  static const _details = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(categoryIdentifier: 'reminder'),
    macOS: DarwinNotificationDetails(categoryIdentifier: 'reminder'),
  );

  /// Schedules a daily repeating notification at [hour]:[minute] local time.
  Future<Result<void>> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) {
    return _schedule(
      id: id,
      title: title,
      body: body,
      firstInstance: _nextInstanceOf(hour, minute),
      matchComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Schedules a weekly repeating notification on [weekday]
  /// (DateTime.monday..sunday) at [hour]:[minute].
  Future<Result<void>> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  }) {
    return _schedule(
      id: id,
      title: title,
      body: body,
      firstInstance: _nextInstanceOfWeekday(weekday, hour, minute),
      matchComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  /// Schedules a single notification for [when] (skipped when in the past).
  Future<Result<void>> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) {
    final scheduled = tz.TZDateTime(
        tz.local, when.year, when.month, when.day, when.hour, when.minute);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
      return Future.value(
          const Result.failure('That time has already passed.'));
    }
    return _schedule(
      id: id,
      title: title,
      body: body,
      firstInstance: scheduled,
      matchComponents: null,
      payload: payload,
    );
  }

  Future<Result<void>> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime firstInstance,
    required DateTimeComponents? matchComponents,
    String? payload,
  }) async {
    if (!isSupported) {
      return const Result.failure('Notifications are not supported on web.');
    }
    try {
      await initialize();
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        firstInstance,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
        payload: payload,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Could not schedule notification.', e);
    }
  }

  /// The next local [hour]:[minute], built with CALENDAR arithmetic.
  ///
  /// `add(Duration(days: 1))` adds 24 absolute hours, so rolling over
  /// into a DST transition day shifted the wall-clock time by an hour —
  /// and because `matchDateTimeComponents` derives the repeat from this
  /// first instance, an 08:00 reminder became a permanent 09:00 one.
  /// Constructing the next calendar day keeps the requested wall time.
  static tz.TZDateTime nextInstanceOf(int hour, int minute, {DateTime? now}) {
    final at = now ?? tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(tz.local, at.year, at.month, at.day, hour,
        minute);
    if (today.isAfter(at)) return today;
    // day + 1 normalizes across month/year ends.
    return tz.TZDateTime(
        tz.local, at.year, at.month, at.day + 1, hour, minute);
  }

  /// The next [weekday] at [hour]:[minute], also by calendar steps.
  static tz.TZDateTime nextInstanceOfWeekday(int weekday, int hour, int minute,
      {DateTime? now}) {
    var scheduled = nextInstanceOf(hour, minute, now: now);
    var guard = 0;
    while (scheduled.weekday != weekday && guard++ < 7) {
      scheduled = tz.TZDateTime(tz.local, scheduled.year, scheduled.month,
          scheduled.day + 1, hour, minute);
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) =>
      nextInstanceOf(hour, minute);

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) =>
      nextInstanceOfWeekday(weekday, hour, minute);

  Future<void> cancel(int id) async {
    if (!isSupported) return;
    await _plugin.cancel(id);
  }

  /// Cancels each id AND its snooze copy. A snoozed notification used to
  /// outlive the reminder it came from — deleting the reminder cancelled
  /// the schedule but left the snooze armed, so it still fired.
  Future<void> cancelMany(Iterable<int> ids) async {
    if (!isSupported) return;
    for (final id in ids) {
      await _plugin.cancel(id);
      await _plugin.cancel(NotificationIds.snoozeFor(id));
    }
  }

  Future<void> cancelAll() async {
    if (!isSupported) return;
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pending() async {
    if (!isSupported) return const [];
    return _plugin.pendingNotificationRequests();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../errors/result.dart';

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

  /// Notification-id offset for snooze copies, well clear of the 31-bit
  /// hash space used for reminder ids.
  static const int _snoozeIdOffset = 0x20000000;

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
          (id + _snoozeIdOffset) & 0x7fffffff,
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

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOf(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancel(int id) async {
    if (!isSupported) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelMany(Iterable<int> ids) async {
    if (!isSupported) return;
    for (final id in ids) {
      await _plugin.cancel(id);
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

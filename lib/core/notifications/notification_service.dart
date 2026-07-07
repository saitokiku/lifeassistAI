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

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(initSettings);
    _initialized = true;
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
    channelDescription: 'Daily operator reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const _details = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  /// Schedules a daily repeating notification at [hour]:[minute] local time.
  Future<Result<void>> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
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
        _nextInstanceOf(hour, minute),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
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

  Future<void> cancel(int id) async {
    if (!isSupported) return;
    await _plugin.cancel(id);
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

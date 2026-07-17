import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/errors/result.dart';
import 'package:life_dashboard/core/notifications/notification_service.dart';
import 'package:life_dashboard/core/notifications/reminder_scheduler.dart';
import 'package:life_dashboard/core/storage/app_database.dart';

/// The armed-notification shape, without the platform plugin: the
/// scheduler's contract is WHICH schedule calls it makes with WHICH ids,
/// times, and payloads. flutter_local_notifications is pinned (^18); on
/// any bump these assertions plus the checklist in docs/release_ios.md
/// are the re-verification gate.
class _RecordingNotifications extends NotificationService {
  final scheduled = <Map<String, Object?>>[];
  final cancelled = <int>[];

  @override
  Future<Result<void>> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    scheduled.add({
      'kind': 'daily',
      'id': id,
      'title': title,
      'body': body,
      'hour': hour,
      'minute': minute,
      'payload': payload,
    });
    return const Result.success(null);
  }

  @override
  Future<Result<void>> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    scheduled.add({
      'kind': 'weekly',
      'id': id,
      'weekday': weekday,
      'hour': hour,
      'minute': minute,
      'payload': payload,
    });
    return const Result.success(null);
  }

  @override
  Future<Result<void>> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    scheduled.add({
      'kind': 'once',
      'id': id,
      'when': when,
      'payload': payload,
    });
    return const Result.success(null);
  }

  @override
  Future<void> cancelMany(Iterable<int> ids) async => cancelled.addAll(ids);

  @override
  Future<void> cancel(int id) async => cancelled.add(id);
}

Reminder reminder({
  String type = 'custom',
  int weekdays = 127,
  String? oneShotDate,
  bool enabled = true,
  int notificationId = 1000,
  int hour = 8,
  int minute = 30,
}) =>
    Reminder(
      id: 'r-$notificationId',
      title: 'Nudge',
      message: 'msg',
      type: type,
      hour: hour,
      minute: minute,
      weekdays: weekdays,
      oneShotDate: oneShotDate,
      enabled: enabled,
      notificationId: notificationId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  late _RecordingNotifications notifications;
  late ReminderScheduler scheduler;

  setUp(() {
    notifications = _RecordingNotifications();
    scheduler = ReminderScheduler(notifications);
  });

  group('ReminderScheduler — armed-notification shape', () {
    test('daily reminder arms exactly one daily schedule on the base id',
        () async {
      final r = reminder(type: 'morningCommand');
      final result = await scheduler.syncAll([r], appEnabled: true);

      expect(result.isSuccess, isTrue);
      expect(notifications.scheduled, hasLength(1));
      final call = notifications.scheduled.single;
      expect(call['kind'], 'daily');
      expect(call['id'], r.notificationId);
      expect(call['hour'], 8);
      expect(call['minute'], 30);
      expect(call['payload'], 'route:/today');
    });

    test('weekly reminder arms one variant id per selected weekday',
        () async {
      // Monday (bit 0) + Wednesday (bit 2).
      final r = reminder(type: 'dailyAction', weekdays: 0x05);
      await scheduler.syncAll([r], appEnabled: true);

      expect(notifications.scheduled, hasLength(2));
      final byWeekday = {
        for (final c in notifications.scheduled) c['weekday']: c,
      };
      expect(byWeekday.keys.toSet(), {DateTime.monday, DateTime.wednesday});
      expect(
        byWeekday[DateTime.monday]!['id'],
        ReminderScheduler.weekdayIdFor(r.notificationId, DateTime.monday),
      );
      expect(
        byWeekday[DateTime.wednesday]!['id'],
        ReminderScheduler.weekdayIdFor(r.notificationId, DateTime.wednesday),
      );
      // The nudge IS the input: daily-step taps open the capture sheet.
      expect(
        byWeekday[DateTime.monday]!['payload'],
        'lifeassist://capture?type=step',
      );
    });

    test('one-shot arms a single dated schedule at the reminder time',
        () async {
      final r = reminder(oneShotDate: '2030-01-15', hour: 9, minute: 5);
      await scheduler.syncAll([r], appEnabled: true);

      expect(notifications.scheduled, hasLength(1));
      final call = notifications.scheduled.single;
      expect(call['kind'], 'once');
      expect(call['id'], r.notificationId);
      expect(call['when'], DateTime(2030, 1, 15, 9, 5));
    });

    test('sync cancels the FULL id space first, disabled arms nothing',
        () async {
      final r = reminder(enabled: false);
      final result = await scheduler.syncAll([r], appEnabled: true);

      expect(result.isSuccess, isTrue);
      expect(notifications.scheduled, isEmpty);
      // Base id + 7 weekday variants, all distinct, all 31-bit positive.
      final ids = ReminderScheduler.allIdsFor(r).toList();
      expect(ids, hasLength(8));
      expect(ids.toSet(), hasLength(8));
      expect(ids.every((id) => id >= 0 && id <= 0x7fffffff), isTrue);
      expect(notifications.cancelled.toSet(), ids.toSet());
    });

    test('appEnabled=false is a cancel-only pass', () async {
      final r = reminder();
      final result = await scheduler.syncAll([r], appEnabled: false);
      expect(result.isSuccess, isTrue);
      expect(notifications.scheduled, isEmpty);
      expect(notifications.cancelled, isNotEmpty);
    });
  });
}

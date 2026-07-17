import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/health/health_habit_sync.dart';
import 'package:life_dashboard/core/health/health_service.dart';
import 'package:life_dashboard/core/storage/app_database.dart';

/// The Phase 5 contract: health data becomes habit logs ONLY through the
/// user's explicit mapping, manual logs always win, and the sync's own
/// writes stay honest when the data no longer supports them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

  const channel = MethodChannel('lifeassist/health');
  late AppDatabase db;
  Map<String, Object?> summary = {};

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    summary = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'availability':
          return 'ready';
        case 'dailySummary':
          return summary;
        default:
          return null;
      }
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await db.close();
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  final at = DateTime(2026, 7, 11, 9);

  Future<Habit> plantHabit({
    String type = 'boolean',
    String? metric = 'steps',
    double? target = 8000,
  }) async {
    final habit = Habit(
      id: 'h1',
      name: 'Walk',
      type: type,
      unit: null,
      weekdays: 127,
      reminderHour: null,
      reminderMinute: null,
      healthMetric: metric,
      healthTarget: target,
      sortOrder: 0,
      isArchived: false,
      createdAt: at,
    );
    await db.into(db.habits).insert(habit);
    return habit;
  }

  HealthHabitSync sync() =>
      HealthHabitSync(db, HealthService(channel: channel));

  test('boolean habit checks itself when the metric reaches target',
      () async {
    await plantHabit();
    summary = {'steps': 9200};
    final changed = await sync().sync(now: at);
    expect(changed, greaterThan(0));
    final log = (await db.select(db.habitLogs).get())
        .firstWhere((l) => l.date == '2026-07-11');
    expect(log.value, 1);
    expect(log.source, 'health');

    // Second run is a no-op — no duplicate, no churn.
    expect(await sync().sync(now: at), 0);
  });

  test('below target writes nothing; a stale health check is removed',
      () async {
    await plantHabit();
    summary = {'steps': 3000};
    expect(await sync().sync(now: at), 0);
    expect(await db.select(db.habitLogs).get(), isEmpty);

    // A health-written check from earlier (say the target was raised)
    // is removed when the data no longer meets it.
    await db.into(db.habitLogs).insert(const HabitLog(
          id: 'stale',
          habitId: 'h1',
          date: '2026-07-11',
          value: 1,
          note: null,
          source: 'health',
        ));
    expect(await sync().sync(now: at), greaterThan(0));
    expect(
      (await db.select(db.habitLogs).get())
          .where((l) => l.date == '2026-07-11'),
      isEmpty,
    );
  });

  test('a manual log is never touched', () async {
    await plantHabit();
    await db.into(db.habitLogs).insert(const HabitLog(
          id: 'mine',
          habitId: 'h1',
          date: '2026-07-11',
          value: 1,
          note: 'did it before breakfast',
          source: 'manual',
        ));
    summary = {'steps': 500}; // way below target
    expect(await sync().sync(now: at), 0);
    final log = (await db.select(db.habitLogs).get()).single;
    expect(log.id, 'mine');
    expect(log.note, 'did it before breakfast');
  });

  test('numeric habit logs the real value and updates it as data grows',
      () async {
    await plantHabit(type: 'numeric', metric: 'workoutMinutes', target: null);
    summary = {'workoutMinutes': 22.4};
    await sync().sync(now: at);
    var log = (await db.select(db.habitLogs).get())
        .firstWhere((l) => l.date == '2026-07-11');
    expect(log.value, 22.4);
    expect(log.source, 'health');

    summary = {'workoutMinutes': 48.0};
    await sync().sync(now: at);
    log = (await db.select(db.habitLogs).get())
        .firstWhere((l) => l.date == '2026-07-11');
    expect(log.value, 48.0);
  });

  test('null metric data changes nothing (no data == no permission)',
      () async {
    await plantHabit();
    summary = {'steps': null};
    expect(await sync().sync(now: at), 0);
    expect(await db.select(db.habitLogs).get(), isEmpty);
  });

  test('same instance throttles repeat syncs; force bypasses', () async {
    await plantHabit();
    summary = {'steps': 9200};
    final instance = sync();
    expect(await instance.sync(now: at), greaterThan(0));

    // Data changed one minute later, but the window hasn't passed —
    // the foreground burst is absorbed.
    summary = {'steps': 100};
    final oneMinute = at.add(const Duration(minutes: 1));
    expect(await instance.sync(now: oneMinute), 0);
    // Force is the user-initiated path (Settings connect): runs now,
    // and removes the check the lower number no longer supports.
    expect(await instance.sync(now: oneMinute, force: true), greaterThan(0));

    // Past the window, syncs flow again (fresh check re-written).
    summary = {'steps': 9200};
    final later = at.add(HealthHabitSync.throttleWindow +
        const Duration(minutes: 6));
    expect(await instance.sync(now: later), greaterThan(0));
  });
}

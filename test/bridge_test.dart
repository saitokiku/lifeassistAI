import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/native/bridge_paths.dart';
import 'package:life_dashboard/core/native/capture_queue_drain.dart';
import 'package:life_dashboard/core/native/entity_mirror_service.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/storage/seed_service.dart';

/// The Dart↔Swift bridge is plain files by design so it can be pinned
/// down here: the mirror the Siri entity queries read, and the capture
/// queue whose records must land exactly once no matter how many times
/// a drain sees them.
void main() {
  late AppDatabase db;
  late Directory tmp;
  late BridgePaths paths;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    tmp = Directory.systemTemp.createTempSync('bridge_test');
    paths = BridgePaths(Directory('${tmp.path}/lifeassist_bridge'));
    await paths.ensureDirs();
  });

  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  final at = DateTime(2026, 7, 10);

  Future<String> plantCategory({String name = 'Groceries'}) async {
    const id = 'cat-1';
    await db.into(db.budgetCategories).insert(BudgetCategory(
          id: id,
          name: name,
          monthlyTargetCents: 40000,
          flagType: 'warnOverTarget',
          sortOrder: 0,
          createdAt: at,
          updatedAt: at,
        ));
    return id;
  }

  Future<String> plantBudget({String name = 'Deep work'}) async {
    const id = 'budget-1';
    await db.into(db.timeBudgets).insert(TimeBudget(
          id: id,
          name: name,
          kind: 'goal',
          weeklyTargetHours: 10,
          sortOrder: 0,
        ));
    return id;
  }

  Future<String> plantHabit({String name = 'Stretch'}) async {
    const id = 'habit-1';
    await db.into(db.habits).insert(Habit(
          id: id,
          name: name,
          type: 'boolean',
          unit: null,
          weekdays: 127,
          notificationId: 8,
          sortOrder: 0,
          isArchived: false,
          createdAt: at,
        ));
    return id;
  }

  File pendingFile(String name, Map<String, dynamic> record) {
    final file = File('${paths.pendingDir.path}/$name');
    file.writeAsStringSync(jsonEncode(record));
    return file;
  }

  Map<String, dynamic> expenseRecord(String id, {String? categoryName}) => {
        'v': 1,
        'id': id,
        'createdAt': '2026-07-10T09:00:00Z',
        'source': 'siri',
        'type': 'expense',
        'fields': {
          'amountCents': 1250,
          'text': 'groceries run',
          if (categoryName != null) 'categoryName': categoryName,
        },
      };

  group('EntityMirrorService', () {
    test('writes the versioned envelope with the app nouns', () async {
      await plantCategory();
      await plantBudget();
      await plantHabit();

      final mirror = EntityMirrorService(db, paths);
      await mirror.writeNow();

      final json =
          jsonDecode(paths.entitiesFile.readAsStringSync()) as Map;
      expect(json['v'], EntityMirrorService.version);
      expect((json['budgetCategories'] as List).single['name'], 'Groceries');
      expect((json['timeBudgets'] as List).single['name'], 'Deep work');
      expect((json['habits'] as List).single['name'], 'Stretch');
      // Atomic write leaves no tmp behind.
      expect(File('${paths.entitiesFile.path}.tmp').existsSync(), isFalse);
    });

    test('start() rewrites after a table change (debounced)', () async {
      final mirror = EntityMirrorService(db, paths);
      await mirror.start();
      expect(
        (jsonDecode(paths.entitiesFile.readAsStringSync())
                as Map)['budgetCategories'],
        isEmpty,
      );

      await plantCategory(name: 'Coffee');
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final json =
          jsonDecode(paths.entitiesFile.readAsStringSync()) as Map;
      expect((json['budgetCategories'] as List).single['name'], 'Coffee');
      await mirror.stop();
    });

    test('archived habits stay out of the mirror', () async {
      final id = await plantHabit();
      await (db.update(db.habits)..where((t) => t.id.equals(id)))
          .write(const HabitsCompanion(isArchived: Value(true)));
      final mirror = EntityMirrorService(db, paths);
      await mirror.writeNow();
      expect(
        (jsonDecode(paths.entitiesFile.readAsStringSync())
            as Map)['habits'],
        isEmpty,
      );
    });
  });

  group('CaptureQueueDrain', () {
    test('imports an expense exactly once across repeated drains', () async {
      final catId = await plantCategory();
      pendingFile('1000-aaa.json', expenseRecord('aaa', categoryName: 'grocer'));

      final drain = CaptureQueueDrain(db, paths);
      final first = await drain.drain();
      expect(first.imported, 1);

      // The same record delivered again (at-least-once world).
      pendingFile('1001-aaa.json', expenseRecord('aaa', categoryName: 'grocer'));
      final second = await drain.drain();
      expect(second.imported, 1); // file consumed…

      final rows = await db.select(db.transactionEntries).get();
      expect(rows, hasLength(1)); // …but the row is still singular
      expect(rows.single.id, 'aaa');
      expect(rows.single.amountCents, 1250);
      expect(rows.single.categoryId, catId);
      expect(paths.pendingDir.listSync(), isEmpty);
    });

    test('unknown category saves uncategorized, spoken name preserved',
        () async {
      pendingFile(
          '1000-bbb.json', expenseRecord('bbb', categoryName: 'zzz-unknown'));
      await CaptureQueueDrain(db, paths).drain();
      final row = (await db.select(db.transactionEntries).get()).single;
      expect(row.categoryId, isNull);
      expect(row.description, contains('zzz-unknown'));
    });

    test('time with an unresolvable budget goes to failed/, not the void',
        () async {
      pendingFile('1000-ccc.json', {
        'v': 1,
        'id': 'ccc',
        'createdAt': '2026-07-10T09:00:00Z',
        'type': 'time',
        'fields': {'hours': 2.0, 'budgetName': 'no-such-budget'},
      });
      final result = await CaptureQueueDrain(db, paths).drain();
      expect(result.imported, 0);
      expect(result.failed, 1);
      expect(await db.select(db.timeBlocks).get(), isEmpty);
      expect(paths.failedDir.listSync(), hasLength(1));
      expect(CaptureQueueDrain.failedCount(paths), 1);
    });

    test('malformed json lands in failed/ and never crashes the drain',
        () async {
      File('${paths.pendingDir.path}/1000-junk.json')
          .writeAsStringSync('{not json');
      pendingFile('1001-ok.json', expenseRecord('ok1'));
      final result = await CaptureQueueDrain(db, paths).drain();
      expect(result.imported, 1);
      expect(result.failed, 1);
      expect(paths.failedDir.listSync(), hasLength(1));
    });

    test('habit check dedupes by habit and day', () async {
      final habitId = await plantHabit();
      Map<String, dynamic> check(String id) => {
            'v': 1,
            'id': id,
            'createdAt': '2026-07-10T09:00:00Z',
            'type': 'habitLog',
            'fields': {'habitId': habitId, 'value': 1},
          };
      pendingFile('1000-h1.json', check('h1'));
      pendingFile('1001-h2.json', check('h2'));
      await CaptureQueueDrain(db, paths).drain();
      expect(await db.select(db.habitLogs).get(), hasLength(1));
    });

    test('reminder carries the Swift-armed notification id through',
        () async {
      pendingFile('1000-rrr.json', {
        'v': 1,
        'id': 'rrr',
        'createdAt': '2026-07-10T09:00:00Z',
        'type': 'reminder',
        'fields': {'text': 'Stretch', 'hour': 15, 'minute': 30},
        'notification': {'id': 123456789, 'armed': true},
      });
      final result = await CaptureQueueDrain(db, paths).drain();
      expect(result.remindersChanged, isTrue);
      final row = (await db.select(db.reminders).get()).single;
      expect(row.notificationId, 123456789);
      expect(row.hour, 15);
      expect(row.minute, 30);
      expect(row.enabled, isTrue);
    });

    test('reminder without an armed id falls back to the derived one',
        () async {
      pendingFile('1000-sss.json', {
        'v': 1,
        'id': 'sss',
        'createdAt': '2026-07-10T09:00:00Z',
        'type': 'reminder',
        'fields': {'text': 'Water'},
      });
      await CaptureQueueDrain(db, paths).drain();
      final row = (await db.select(db.reminders).get()).single;
      expect(row.notificationId, SeedService.notificationIdFor('sss'));
    });

    test('undo deletes a still-pending capture before it ever lands',
        () async {
      pendingFile('1000-ddd.json', expenseRecord('ddd'));
      pendingFile('1001-undo.json', {
        'v': 1,
        'id': 'undo-1',
        'createdAt': '2026-07-10T09:01:00Z',
        'type': 'undo',
        'fields': {'targetId': 'ddd'},
      });
      // Order: expense drains first (older name), THEN undo removes it —
      // wait: undo of an already-imported row deletes the row instead.
      await CaptureQueueDrain(db, paths).drain();
      expect(await db.select(db.transactionEntries).get(), isEmpty);
    });

    test('undo frees a drained reminder and reports its notification id',
        () async {
      pendingFile('1000-eee.json', {
        'v': 1,
        'id': 'eee',
        'createdAt': '2026-07-10T09:00:00Z',
        'type': 'reminder',
        'fields': {'text': 'Call mom', 'hour': 12, 'minute': 0},
        'notification': {'id': 42424242, 'armed': true},
      });
      final drain = CaptureQueueDrain(db, paths);
      await drain.drain();
      expect(await db.select(db.reminders).get(), hasLength(1));

      pendingFile('2000-undo.json', {
        'v': 1,
        'id': 'undo-2',
        'createdAt': '2026-07-10T09:05:00Z',
        'type': 'undo',
        'fields': {'targetId': 'eee'},
      });
      final result = await drain.drain();
      expect(await db.select(db.reminders).get(), isEmpty);
      expect(result.cancelNotificationIds, contains(42424242));
    });

    test('records from a NEWER contract version are refused, kept',
        () async {
      pendingFile('1000-vnext.json', {
        'v': 99,
        'id': 'vnext',
        'type': 'expense',
        'fields': {'amountCents': 100},
      });
      final result = await CaptureQueueDrain(db, paths).drain();
      expect(result.failed, 1);
      expect(paths.failedDir.listSync(), hasLength(1));
    });

    test('failed graveyard is capped', () async {
      for (var i = 0; i < CaptureQueueDrain.failedCap + 5; i++) {
        File('${paths.pendingDir.path}/${1000 + i}-bad$i.json')
            .writeAsStringSync('broken');
      }
      await CaptureQueueDrain(db, paths).drain();
      expect(
        paths.failedDir.listSync().length,
        CaptureQueueDrain.failedCap,
      );
      await CaptureQueueDrain.clearFailed(paths);
      expect(CaptureQueueDrain.failedCount(paths), 0);
    });
  });
}

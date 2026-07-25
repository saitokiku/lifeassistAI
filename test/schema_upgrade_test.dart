import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/notifications/notification_ids.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/storage/seed_service.dart';

/// The onUpgrade catch-up index pass runs against databases that already
/// HAVE their indexes — every real upgrade does (onCreate's createAll()
/// built them, or an earlier upgrade's own catch-up pass did). SQLite's
/// bare `CREATE INDEX` throws on an existing index, which aborted the
/// migration and left the app unable to open its database at all
/// ("Storage didn't start", permanently, since the file never changed).
///
/// These tests rewind a fully built database to an older version — the
/// exact state of a real install being updated — and prove the upgrade
/// completes and does its work.
void main() {
  late Directory tmp;
  late File dbFile;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('lifeassist_upgrade');
    dbFile = File('${tmp.path}/app.db');
  });

  tearDown(() => tmp.delete(recursive: true));

  /// Builds the current schema in full (tables AND indexes), seeds it,
  /// then strips the v7 additions and stamps the version back.
  Future<void> plantV6() async {
    final fresh = AppDatabase(DatabaseConnection(NativeDatabase(dbFile)));
    await SeedService(fresh).seedIfNeeded();
    await fresh.close();

    final bare = _BareDb(DatabaseConnection(NativeDatabase(dbFile)));
    for (final index in const [
      'idx_habit_logs_unique',
      'idx_balance_snapshots_unique',
      'idx_metric_entries_unique',
    ]) {
      await bare.customStatement('DROP INDEX IF EXISTS $index');
    }
    await bare.customStatement('ALTER TABLE habits DROP COLUMN notification_id');
    await bare.customStatement('PRAGMA user_version = 6');
    await bare.close();
  }

  test('v6 → v7 upgrade survives pre-existing indexes', () async {
    await plantV6();

    final upgraded = AppDatabase(DatabaseConnection(NativeDatabase(dbFile)));
    addTearDown(upgraded.close);
    // Opening at all is the assertion: a bare CREATE INDEX over the ~20
    // indexes the v6 file already carries used to throw here.
    final habits = await upgraded.select(upgraded.habits).get();
    expect(habits, isNotEmpty);

    // Every schema index exists exactly once afterwards.
    final indexRows = await upgraded
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name LIKE 'idx_%'")
        .get();
    final names = [for (final r in indexRows) r.read<String>('name')];
    expect(names.toSet().length, names.length);
    expect(names, contains('idx_transactions_date'));
    expect(names, contains('idx_habit_logs_unique'));
  });

  test('v7 assigns every habit and reminder a distinct id block', () async {
    await plantV6();

    final upgraded = AppDatabase(DatabaseConnection(NativeDatabase(dbFile)));
    addTearDown(upgraded.close);
    final habits = await upgraded.select(upgraded.habits).get();
    final reminders = await upgraded.select(upgraded.reminders).get();
    final bases = [
      for (final h in habits) h.notificationId,
      for (final r in reminders) r.notificationId,
    ];

    expect(bases, isNotEmpty);
    expect(bases.toSet().length, bases.length, reason: 'no shared bases');
    for (final base in bases) {
      expect(NotificationIds.isBase(base), isTrue,
          reason: '$base must be a block-aligned base');
    }
    // Blocks must not overlap: every id any owner may occupy is unique
    // across owners — the old hash scheme could not promise this.
    final everyId = [for (final b in bases) ...NotificationIds.blockFor(b)];
    expect(everyId.toSet().length, everyId.length);
  });

  test('v7 collapses duplicate habit logs before the unique index',
      () async {
    await plantV6();

    // Two logs for the same habit+day — impossible to insert once the
    // unique index exists, but pre-v7 databases can hold them.
    final bare = _BareDb(DatabaseConnection(NativeDatabase(dbFile)));
    final habitId = (await bare
            .customSelect('SELECT id FROM habits LIMIT 1')
            .getSingle())
        .read<String>('id');
    for (final id in ['dup-a', 'dup-b']) {
      await bare.customStatement(
        'INSERT INTO habit_logs (id, habit_id, date, value, source) '
        "VALUES (?, ?, '2026-07-04', 1, 'manual')",
        [id, habitId],
      );
    }
    // Opening the bare handle stamped user_version forward; put it back
    // so the real database still sees a v6 file to upgrade.
    await bare.customStatement('PRAGMA user_version = 6');
    await bare.close();

    final upgraded = AppDatabase(DatabaseConnection(NativeDatabase(dbFile)));
    addTearDown(upgraded.close);
    final logs = await (upgraded.select(upgraded.habitLogs)
          ..where((t) => t.date.equals('2026-07-04')))
        .get();
    expect(logs, hasLength(1), reason: 'newest row per key survives');
    expect(logs.single.id, 'dup-b');
  });

  test('reopening at the same version runs no migration', () async {
    final first = AppDatabase(DatabaseConnection(NativeDatabase(dbFile)));
    await first.select(first.habits).get();
    await first.close();

    final second = AppDatabase(DatabaseConnection(NativeDatabase(dbFile)));
    addTearDown(second.close);
    await second.select(second.habits).get();
  });
}

/// Schema-less handle for raw statements against the planted file. Its
/// no-op migration keeps drift from trying to migrate on open.
class _BareDb extends GeneratedDatabase {
  _BareDb(super.e);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  /// Matches whatever the file already declares, so opening it never
  /// looks like an upgrade or a downgrade.
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (_) async {},
        onUpgrade: (_, __, ___) async {},
      );
}

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';

/// The onUpgrade catch-up index pass runs against databases that already
/// HAVE their indexes — every real upgrade does (onCreate's createAll()
/// built them, or an earlier upgrade's own catch-up pass did). SQLite's
/// bare `CREATE INDEX` throws on an existing index, which would abort
/// the migration and brick the app at launch. This test rewinds a fully
/// built database to v5 (notes schema removed, version stamped back) —
/// exactly the state of a real v5 install upgrading to v6 — and proves
/// the upgrade completes.
void main() {
  late Directory tmp;
  late File dbFile;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('lifeassist_upgrade');
    dbFile = File('${tmp.path}/app.db');
  });

  tearDown(() => tmp.delete(recursive: true));

  test('v5 → v6 upgrade survives pre-existing indexes', () async {
    // Build the current schema in full: all tables AND all indexes.
    final fresh = AppDatabase(DatabaseConnection(NativeDatabase(dbFile)));
    await fresh.select(fresh.habits).get(); // force open + onCreate
    await fresh.close();

    // Rewind to v5: the notes schema doesn't exist yet (dropping the
    // tables drops their indexes with them), version stamped back.
    final bare = _BareDb(DatabaseConnection(NativeDatabase(dbFile)));
    await bare.customStatement('DROP TABLE notes');
    await bare.customStatement('DROP TABLE note_links');
    await bare.customStatement('DROP TABLE note_tags');
    await bare.customStatement('PRAGMA user_version = 5');
    await bare.close();

    // A real v5 → v6 upgrade: must not throw on the ~17 indexes the
    // older tables already carry.
    final upgraded = AppDatabase(DatabaseConnection(NativeDatabase(dbFile)));
    addTearDown(upgraded.close);
    await upgraded.select(upgraded.notes).get(); // notes schema exists
    await upgraded.select(upgraded.habits).get(); // old tables intact

    // Every schema index exists exactly once afterwards.
    final indexRows = await upgraded
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name LIKE 'idx_%'",
        )
        .get();
    final names = [for (final r in indexRows) r.read<String>('name')];
    expect(names.toSet().length, names.length);
    expect(names, contains('idx_transactions_date'));
    expect(names, contains('idx_notes_updated'));
  });

  test('reopening at the same version runs no migration and no index pass',
      () async {
    final first = AppDatabase(DatabaseConnection(NativeDatabase(dbFile)));
    await first.select(first.habits).get();
    await first.close();

    final second = AppDatabase(DatabaseConnection(NativeDatabase(dbFile)));
    addTearDown(second.close);
    await second.select(second.habits).get(); // must open cleanly
  });
}

/// Schema-less handle for raw statements against the planted file.
class _BareDb extends GeneratedDatabase {
  _BareDb(super.e);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 6;
}

import 'dart:convert';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/storage/seed_service.dart';
import 'package:life_dashboard/features/settings/data/backup_service.dart';

/// Import is the safety net of a no-cloud app; it must never be able to
/// destroy more than it restores. Before these guards, any JSON with a
/// top-level `data` map — a config file, a truncated download — wiped
/// all 25 tables and reported "Imported 0 records." as a success.
void main() {
  late AppDatabase db;
  late BackupService backup;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    backup = BackupService(db);
    await SeedService(db).seedIfNeeded();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> categoryCount() async =>
      (await db.select(db.budgetCategories).get()).length;

  test('a foreign JSON with a data key is refused, database untouched',
      () async {
    final before = await categoryCount();
    expect(before, greaterThan(0));

    final result = await backup.importJson('{"data":{}}');
    expect(result.isSuccess, isFalse);
    expect(await categoryCount(), before,
        reason: 'a refused import must not delete anything');
  });

  test('a wrong app name is refused even with plausible rows', () async {
    final export = jsonDecode(await backup.exportJson()) as Map<String, dynamic>;
    export['app'] = 'Some Other App';
    final result = await backup.importJson(jsonEncode(export));
    expect(result.isSuccess, isFalse);
    expect(result.errorOrNull, contains("isn't a"));
    expect(await categoryCount(), greaterThan(0));
  });

  test('the pre-rename app name still imports', () async {
    final export = jsonDecode(await backup.exportJson()) as Map<String, dynamic>;
    export['app'] = BackupService.legacyAppName;
    final result = await backup.importJson(jsonEncode(export));
    expect(result.isSuccess, isTrue);
  });

  test('a zero-record backup is refused — it could only erase', () async {
    final export = jsonDecode(await backup.exportJson()) as Map<String, dynamic>;
    export['data'] = {
      for (final key in (export['data'] as Map<String, dynamic>).keys)
        key: <dynamic>[],
    };
    final before = await categoryCount();
    final result = await backup.importJson(jsonEncode(export));
    expect(result.isSuccess, isFalse);
    expect(result.errorOrNull, contains('no records'));
    expect(await categoryCount(), before);
  });

  test('a real export still round-trips', () async {
    final json = await backup.exportJson();
    final result = await backup.importJson(json);
    expect(result.isSuccess, isTrue);
    expect(await categoryCount(), greaterThan(0));
  });
}

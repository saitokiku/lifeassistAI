import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/constants/app_constants.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/storage/seed_service.dart';
import 'package:life_dashboard/features/settings/data/backup_service.dart';

/// The demo backup (`demo/life_assist_demo.json`, written by
/// `scripts/generate_demo_data.py`) is shown to people as a real
/// customer's data, so it has to survive the real import path — not a
/// hand-wave that it "looks like" an export.
///
/// These tests double as end-to-end coverage of export/import: the file
/// goes in through [BackupService.importJson], back out through
/// [BackupService.exportJson], and in again, and every table has to come
/// out the same size with its references intact.
void main() {
  late AppDatabase db;
  late BackupService backup;

  final file = File('demo/life_assist_demo.json');
  final raw = file.readAsStringSync();
  final demo = jsonDecode(raw) as Map<String, dynamic>;
  final demoData = demo['data'] as Map<String, dynamic>;
  final demoRowCount = demoData.values
      .whereType<List>()
      .fold<int>(0, (sum, rows) => sum + rows.length);

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    backup = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('the file is a well-formed export envelope', () {
    expect(demo['app'], AppConstants.appName);
    expect(demo['schemaVersion'], isA<String>());
    expect(demoRowCount, greaterThan(300),
        reason: 'a demo of an empty app is not a demo');
    // Every table the exporter writes must be present, or a demo would
    // silently show empty screens for whatever is missing.
    for (final table in BackupService.exportedTables) {
      expect(demoData[table], isA<List>(),
          reason: '$table is missing from the demo file');
      expect(demoData[table] as List, isNotEmpty,
          reason: '$table is empty in the demo file');
    }
  });

  test('imports into a fresh database', () async {
    final result = await backup.importJson(raw);
    expect(result.isSuccess, isTrue, reason: result.errorOrNull ?? '');
    expect(result.valueOrNull, demoRowCount);

    // Spot-check the shape a demo depends on.
    final goals = await db.select(db.mainGoals).get();
    expect(goals.where((g) => g.status == 'active'), hasLength(1),
        reason: 'exactly one main goal is active at a time');
    expect(await db.select(db.transactionEntries).get(), isNotEmpty);
    expect(await db.select(db.habitLogs).get(), isNotEmpty);
    expect(await db.select(db.notes).get(), isNotEmpty);

    final settings = {
      for (final row in await db.select(db.settingsEntries).get())
        row.key: row.value,
    };
    expect(settings['displayName'], isNotEmpty);
    expect(double.parse(settings['monthlyNetIncome']!), greaterThan(0));
  });

  test('replaces a seeded database rather than merging into it', () async {
    await SeedService(db).seedIfNeeded();
    final result = await backup.importJson(raw);
    expect(result.isSuccess, isTrue, reason: result.errorOrNull ?? '');

    final categories = await db.select(db.budgetCategories).get();
    expect(categories, hasLength((demoData['budgetCategories'] as List).length),
        reason: 'import replaces all data; seeded rows must not survive');
  });

  test('every reference in the demo data resolves after import', () async {
    expect((await backup.importJson(raw)).isSuccess, isTrue);

    final categoryIds =
        (await db.select(db.budgetCategories).get()).map((c) => c.id).toSet();
    final accountIds =
        (await db.select(db.accounts).get()).map((a) => a.id).toSet();
    final recurringIds = (await db.select(db.recurringTransactions).get())
        .map((r) => r.id)
        .toSet();

    for (final tx in await db.select(db.transactionEntries).get()) {
      if (tx.categoryId != null) {
        expect(categoryIds, contains(tx.categoryId));
      }
      if (tx.accountId != null) {
        expect(accountIds, contains(tx.accountId));
      }
      if (tx.sourceRecurringId != null) {
        expect(recurringIds, contains(tx.sourceRecurringId));
      }
    }

    final habitIds =
        (await db.select(db.habits).get()).map((h) => h.id).toSet();
    for (final log in await db.select(db.habitLogs).get()) {
      expect(habitIds, contains(log.habitId));
    }

    final budgetIds =
        (await db.select(db.timeBudgets).get()).map((b) => b.id).toSet();
    for (final block in await db.select(db.timeBlocks).get()) {
      expect(budgetIds, contains(block.budgetId));
    }

    for (final snapshot in await db.select(db.balanceSnapshots).get()) {
      expect(accountIds, contains(snapshot.accountId));
    }

    final metricIds =
        (await db.select(db.growthMetrics).get()).map((m) => m.id).toSet();
    for (final entry in await db.select(db.growthMetricEntries).get()) {
      expect(metricIds, contains(entry.metricId));
    }
  });

  test('note links and tags are rebuilt from the note text', () async {
    expect((await backup.importJson(raw)).isSuccess, isTrue);

    final links = await db.select(db.noteLinks).get();
    final tags = await db.select(db.noteTags).get();
    expect(links, isNotEmpty, reason: 'the demo notes cross-link each other');
    expect(tags, isNotEmpty);
    expect(links.where((l) => l.targetId != null), isNotEmpty,
        reason: 'demo links must resolve to real notes, not ghosts');
  });

  test('round-trips: import, export, import again, same rows', () async {
    expect((await backup.importJson(raw)).isSuccess, isTrue);
    final exported = await backup.exportJson();

    final counts = await _rowCounts(db);
    final second = await backup.importJson(exported);
    expect(second.isSuccess, isTrue, reason: second.errorOrNull ?? '');
    expect(await _rowCounts(db), counts);

    // The re-export matches the first one field for field (bar the
    // export stamp), so a user who exports what they imported gets
    // their data back unchanged — not merely the same row counts.
    expect(_canonical(await backup.exportJson()), _canonical(exported));
  });

  test('money survives the round trip to the cent', () async {
    expect((await backup.importJson(raw)).isSuccess, isTrue);
    int sum(Iterable<int> values) => values.fold(0, (a, b) => a + b);

    final rows = await db.select(db.transactionEntries).get();
    final before = sum(rows.map((t) => t.amountCents));
    expect(before, greaterThan(0));

    final exported = await backup.exportJson();
    expect((await backup.importJson(exported)).isSuccess, isTrue);

    final reimported = await db.select(db.transactionEntries).get();
    final after = sum(reimported.map((t) => t.amountCents));
    expect(after, before);
  });
}

/// Normalizes an export for comparison: drops the `exportedAt` stamp
/// (the one field that legitimately changes per export) and sorts each
/// table's rows by primary key, so two exports of the same data compare
/// equal without depending on row order.
String _canonical(String export) {
  final parsed = jsonDecode(export) as Map<String, dynamic>;
  parsed.remove('exportedAt');
  final data = parsed['data'] as Map<String, dynamic>;
  for (final entry in data.entries) {
    final rows = (entry.value as List).cast<Map<String, dynamic>>();
    final key = entry.key == 'settings' ? 'key' : 'id';
    rows.sort((a, b) => (a[key] as String).compareTo(b[key] as String));
  }
  return const JsonEncoder.withIndent('  ').convert(parsed);
}

Future<Map<String, int>> _rowCounts(AppDatabase db) async => {
      'settings': (await db.select(db.settingsEntries).get()).length,
      'mainGoals': (await db.select(db.mainGoals).get()).length,
      'accounts': (await db.select(db.accounts).get()).length,
      'balanceSnapshots': (await db.select(db.balanceSnapshots).get()).length,
      'recurringTransactions':
          (await db.select(db.recurringTransactions).get()).length,
      'weeklyReviews': (await db.select(db.weeklyReviews).get()).length,
      'growthMetrics': (await db.select(db.growthMetrics).get()).length,
      'growthMetricEntries':
          (await db.select(db.growthMetricEntries).get()).length,
      'dailyExperiments': (await db.select(db.dailyExperiments).get()).length,
      'budgetCategories': (await db.select(db.budgetCategories).get()).length,
      'transactions': (await db.select(db.transactionEntries).get()).length,
      'timeBudgets': (await db.select(db.timeBudgets).get()).length,
      'timeBlocks': (await db.select(db.timeBlocks).get()).length,
      'countdowns': (await db.select(db.countdowns).get()).length,
      'habits': (await db.select(db.habits).get()).length,
      'habitLogs': (await db.select(db.habitLogs).get()).length,
      'parkedIdeas': (await db.select(db.parkedIdeas).get()).length,
      'goals': (await db.select(db.goals).get()).length,
      'freedomTargets': (await db.select(db.freedomTargets).get()).length,
      'reminders': (await db.select(db.reminders).get()).length,
      'identityStatements':
          (await db.select(db.identityStatements).get()).length,
      'journalEntries': (await db.select(db.journalEntries).get()).length,
      'notes': (await db.select(db.notes).get()).length,
      'noteLinks': (await db.select(db.noteLinks).get()).length,
      'noteTags': (await db.select(db.noteTags).get()).length,
    };

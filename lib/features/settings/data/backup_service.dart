import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/result.dart';
import '../../../core/storage/app_database.dart';

/// JSON export/import of every core table. The user owns their data.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const _tableOrder = [
    'settings',
    'growthMetrics',
    'growthMetricEntries',
    'dailyExperiments',
    'budgetCategories',
    'transactions',
    'timeBudgets',
    'timeBlocks',
    'countdowns',
    'habits',
    'habitLogs',
    'parkedIdeas',
    'goals',
    'freedomTargets',
    'reminders',
    'identityStatements',
  ];

  Future<String> exportJson() async {
    final data = <String, List<Map<String, dynamic>>>{
      'settings': [
        for (final r in await _db.select(_db.settingsEntries).get()) r.toJson(),
      ],
      'growthMetrics': [
        for (final r in await _db.select(_db.growthMetrics).get()) r.toJson(),
      ],
      'growthMetricEntries': [
        for (final r in await _db.select(_db.growthMetricEntries).get())
          r.toJson(),
      ],
      'dailyExperiments': [
        for (final r in await _db.select(_db.dailyExperiments).get()) r.toJson(),
      ],
      'budgetCategories': [
        for (final r in await _db.select(_db.budgetCategories).get()) r.toJson(),
      ],
      'transactions': [
        for (final r in await _db.select(_db.transactionEntries).get())
          r.toJson(),
      ],
      'timeBudgets': [
        for (final r in await _db.select(_db.timeBudgets).get()) r.toJson(),
      ],
      'timeBlocks': [
        for (final r in await _db.select(_db.timeBlocks).get()) r.toJson(),
      ],
      'countdowns': [
        for (final r in await _db.select(_db.countdowns).get()) r.toJson(),
      ],
      'habits': [
        for (final r in await _db.select(_db.habits).get()) r.toJson(),
      ],
      'habitLogs': [
        for (final r in await _db.select(_db.habitLogs).get()) r.toJson(),
      ],
      'parkedIdeas': [
        for (final r in await _db.select(_db.parkedIdeas).get()) r.toJson(),
      ],
      'goals': [
        for (final r in await _db.select(_db.goals).get()) r.toJson(),
      ],
      'freedomTargets': [
        for (final r in await _db.select(_db.freedomTargets).get()) r.toJson(),
      ],
      'reminders': [
        for (final r in await _db.select(_db.reminders).get()) r.toJson(),
      ],
      'identityStatements': [
        for (final r in await _db.select(_db.identityStatements).get())
          r.toJson(),
      ],
    };

    return const JsonEncoder.withIndent('  ').convert({
      'app': AppConstants.appName,
      'schemaVersion': AppConstants.exportSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  /// Replaces all data with the backup contents inside one transaction.
  /// Fails without touching the database when the JSON is malformed.
  Future<Result<int>> importJson(String raw) async {
    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return Result.failure('Not valid JSON.', e);
    }

    final data = parsed['data'];
    if (data is! Map<String, dynamic>) {
      return const Result.failure(
          "Missing 'data' section. Is this a Life Dashboard export?");
    }

    List<Map<String, dynamic>> rows(String key) => [
          for (final e in (data[key] as List? ?? const []))
            (e as Map).cast<String, dynamic>(),
        ];

    try {
      var count = 0;
      await _db.transaction(() async {
        await _db.clearAllTables();

        Future<void> insertAll<T extends Table, R extends DataClass>(
          TableInfo<T, R> table,
          String key,
          Insertable<R> Function(Map<String, dynamic>) fromJson,
        ) async {
          for (final row in rows(key)) {
            await _db.into(table).insert(fromJson(row));
            count++;
          }
        }

        await insertAll(_db.settingsEntries, 'settings', SettingsEntry.fromJson);
        await insertAll(
            _db.growthMetrics, 'growthMetrics', GrowthMetric.fromJson);
        await insertAll(_db.growthMetricEntries, 'growthMetricEntries',
            GrowthMetricEntry.fromJson);
        await insertAll(
            _db.dailyExperiments, 'dailyExperiments', DailyExperiment.fromJson);
        await insertAll(
            _db.budgetCategories, 'budgetCategories', BudgetCategory.fromJson);
        await insertAll(
            _db.transactionEntries, 'transactions', TransactionEntry.fromJson);
        await insertAll(_db.timeBudgets, 'timeBudgets', TimeBudget.fromJson);
        await insertAll(_db.timeBlocks, 'timeBlocks', TimeBlock.fromJson);
        await insertAll(_db.countdowns, 'countdowns', Countdown.fromJson);
        await insertAll(_db.habits, 'habits', Habit.fromJson);
        await insertAll(_db.habitLogs, 'habitLogs', HabitLog.fromJson);
        await insertAll(_db.parkedIdeas, 'parkedIdeas', ParkedIdea.fromJson);
        await insertAll(_db.goals, 'goals', Goal.fromJson);
        await insertAll(
            _db.freedomTargets, 'freedomTargets', FreedomTarget.fromJson);
        await insertAll(_db.reminders, 'reminders', Reminder.fromJson);
        await insertAll(_db.identityStatements, 'identityStatements',
            IdentityStatement.fromJson);
      });
      return Result.success(count);
    } catch (e) {
      return Result.failure(
          'Import failed; data was rolled back. (${e.runtimeType})', e);
    }
  }

  /// Sanity check that an export mentions all core tables.
  static List<String> get exportedTables => _tableOrder;
}

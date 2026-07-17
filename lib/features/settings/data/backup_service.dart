import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/result.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/legacy_migration.dart';
import '../../notes/data/notes_repository.dart';

/// JSON export/import of every core table. The user owns their data.
///
/// Exports are versioned (`schemaVersion`); v1 backups predate the universal
/// main-goal system and are normalized on import so nothing is lost.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const _tableOrder = [
    'settings',
    'mainGoals',
    'accounts',
    'balanceSnapshots',
    'recurringTransactions',
    'weeklyReviews',
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
    'journalEntries',
    // NoteLinks/NoteTags are a derived index, not exported: the
    // repository rebuilds both from note text right after import.
    'notes',
  ];

  Future<String> exportJson() async {
    final data = <String, List<Map<String, dynamic>>>{
      'settings': [
        for (final r in await _db.select(_db.settingsEntries).get()) r.toJson(),
      ],
      'mainGoals': [
        for (final r in await _db.select(_db.mainGoals).get()) r.toJson(),
      ],
      'accounts': [
        for (final r in await _db.select(_db.accounts).get()) r.toJson(),
      ],
      'balanceSnapshots': [
        for (final r in await _db.select(_db.balanceSnapshots).get())
          r.toJson(),
      ],
      'recurringTransactions': [
        for (final r in await _db.select(_db.recurringTransactions).get())
          r.toJson(),
      ],
      'weeklyReviews': [
        for (final r in await _db.select(_db.weeklyReviews).get()) r.toJson(),
      ],
      'growthMetrics': [
        for (final r in await _db.select(_db.growthMetrics).get()) r.toJson(),
      ],
      'growthMetricEntries': [
        for (final r in await _db.select(_db.growthMetricEntries).get())
          r.toJson(),
      ],
      'dailyExperiments': [
        for (final r in await _db.select(_db.dailyExperiments).get())
          r.toJson(),
      ],
      'budgetCategories': [
        for (final r in await _db.select(_db.budgetCategories).get())
          r.toJson(),
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
      'journalEntries': [
        for (final r in await _db.select(_db.journalEntries).get()) r.toJson(),
      ],
      'notes': [
        for (final r in await _db.select(_db.notes).get()) r.toJson(),
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
          "Missing 'data' section. Is this a ${AppConstants.appName} export?");
    }

    List<Map<String, dynamic>> rows(String key) => [
          for (final e in (data[key] as List? ?? const []))
            _normalizeLegacyRow(key, (e as Map).cast<String, dynamic>()),
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

        await insertAll(
            _db.settingsEntries, 'settings', SettingsEntry.fromJson);
        await insertAll(_db.mainGoals, 'mainGoals', MainGoal.fromJson);
        await insertAll(_db.accounts, 'accounts', Account.fromJson);
        await insertAll(
            _db.balanceSnapshots, 'balanceSnapshots', BalanceSnapshot.fromJson);
        await insertAll(_db.recurringTransactions, 'recurringTransactions',
            RecurringTransaction.fromJson);
        await insertAll(
            _db.weeklyReviews, 'weeklyReviews', WeeklyReview.fromJson);
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
        await insertAll(
            _db.journalEntries, 'journalEntries', JournalEntry.fromJson);
        await insertAll(_db.notes, 'notes', Note.fromJson);
      });

      // A v1 backup carries Kaizen-era values and no main goal; rewrite it
      // into the universal shape (no-op for v2 backups).
      await LegacyMigration(_db).run();

      // Rebuild the derived link/tag index from the restored note text.
      await NotesRepository(_db).reindexAll();

      return Result.success(count);
    } catch (e) {
      return Result.failure(
          'Import failed; data was rolled back. (${e.runtimeType})', e);
    }
  }

  /// Fills in fields that pre-v2 exports don't have and converts pre-v4
  /// dollar doubles into integer cents, so their rows satisfy today's
  /// schema. Value-level rewrites happen in [LegacyMigration].
  static Map<String, dynamic> _normalizeLegacyRow(
    String table,
    Map<String, dynamic> row,
  ) {
    switch (table) {
      case 'transactions':
        return _centsify({
          'accountId': null,
          'sourceRecurringId': null,
          ...row,
        }, 'amount', 'amountCents');
      case 'recurringTransactions':
        return _centsify(row, 'amount', 'amountCents');
      case 'budgetCategories':
        return _centsify(row, 'monthlyTarget', 'monthlyTargetCents');
      case 'accounts':
        return _centsify(row, 'balance', 'balanceCents');
      case 'balanceSnapshots':
        return _centsify(row, 'balance', 'balanceCents');
      case 'habits':
        return {
          'weekdays': 127,
          'reminderHour': null,
          'reminderMinute': null,
          ...row,
        };
      case 'habitLogs':
        return {'source': 'manual', ...row};
      case 'reminders':
        return {
          'weekdays': 127,
          'oneShotDate': null,
          ...row,
        };
      case 'parkedIdeas':
        if (!row.containsKey('helpsMainGoal')) {
          return {
            ...row,
            'helpsMainGoal': row['directlyHelpsKaizenThisWeek'] ?? false,
          }..remove('directlyHelpsKaizenThisWeek');
        }
        return row;
      case 'goals':
        if (!row.containsKey('isDone') || !row.containsKey('sortOrder')) {
          return {
            'isDone': false,
            'sortOrder': 0,
            ...row,
          };
        }
        return row;
      default:
        return row;
    }
  }

  /// Pre-v4 exports carry dollar doubles under [dollarKey]; rewrite to
  /// integer cents under [centsKey]. v4 rows pass through untouched.
  static Map<String, dynamic> _centsify(
    Map<String, dynamic> row,
    String dollarKey,
    String centsKey,
  ) {
    if (row.containsKey(centsKey)) return row;
    final dollars = row[dollarKey];
    return {
      ...row,
      centsKey: dollars is num ? (dollars * 100).round() : 0,
    }..remove(dollarKey);
  }

  /// Sanity check that an export mentions all core tables.
  static List<String> get exportedTables => _tableOrder;
}

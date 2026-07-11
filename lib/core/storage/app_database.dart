// TableMigration is drift's documented API for column type changes; the
// @experimental marker predates years of stable use.
// ignore_for_file: experimental_member_use

import 'package:drift/drift.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Tables. Dates that mean "a calendar day" are stored as `yyyy-MM-dd` text
// keys so day math is timezone-safe. Timestamps use DateTime columns.
// ---------------------------------------------------------------------------

class GrowthMetrics extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  RealColumn get currentValue => real().withDefault(const Constant(0))();
  RealColumn get weeklyTarget => real().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_metric_entries_metric', columns: {#metricId})
@TableIndex(name: 'idx_metric_entries_date', columns: {#date})
class GrowthMetricEntries extends Table {
  TextColumn get id => text()();
  TextColumn get metricId => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  RealColumn get value => real()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_daily_experiments_date', columns: {#date})
class DailyExperiments extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  TextColumn get hypothesis => text()();
  TextColumn get actionTaken => text()();
  TextColumn get result => text()();
  TextColumn get verdict => text()(); // kill | confirm | iterate
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class BudgetCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Monthly target in integer cents (see lib/core/utils/money.dart).
  IntColumn get monthlyTargetCents =>
      integer().withDefault(const Constant(0))();
  // none | warnOverTarget | warnOverZero | warnOverZeroUnlessIntentional |
  // criticalOverZero  (see BudgetFlagType)
  TextColumn get flagType =>
      text().withDefault(const Constant('warnOverTarget'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_transactions_date', columns: {#date})
@TableIndex(name: 'idx_transactions_category', columns: {#categoryId})
@TableIndex(name: 'idx_transactions_account', columns: {#accountId})
class TransactionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable()(); // null = uncategorized

  /// Which tracked account this touched; null = not account-linked.
  TextColumn get accountId => text().nullable()();

  /// Set when materialized from a recurring expense (idempotence + trace).
  TextColumn get sourceRecurringId => text().nullable()();
  TextColumn get date => text()(); // yyyy-MM-dd

  /// Amount in integer cents — sums stay exact to the cent.
  IntColumn get amountCents => integer()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isIntentional =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class TimeBudgets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  // sleep | job | goal | admin | decompress | meals | exercise |
  // volunteering | meditation | other (see TimeCategoryKind; legacy rows
  // may still carry pre-v2 values — parse() maps them)
  TextColumn get kind => text().withDefault(const Constant('other'))();
  RealColumn get weeklyTargetHours => real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_time_blocks_date', columns: {#date})
@TableIndex(name: 'idx_time_blocks_budget', columns: {#budgetId})
class TimeBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  RealColumn get hours => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Countdowns extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get targetDate => text().nullable()(); // yyyy-MM-dd
  // Dynamic countdowns compute their target at read time:
  // age28 | endOfYear | endOfMonth | rothIraDeadline  (null = fixed date)
  TextColumn get dynamicKey => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()
      .withDefault(const Constant('boolean'))(); // boolean | numeric | duration
  TextColumn get unit => text().nullable()();

  /// Scheduled weekdays (bitmask, bit 0 = Monday). 127 = every day.
  /// Streaks and "due today" respect the schedule.
  IntColumn get weekdays => integer().withDefault(const Constant(127))();

  /// Optional per-habit reminder time; both null = no reminder.
  IntColumn get reminderHour => integer().nullable()();
  IntColumn get reminderMinute => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_habit_logs_habit', columns: {#habitId})
@TableIndex(name: 'idx_habit_logs_date', columns: {#date})
class HabitLogs extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  // boolean habits store 1/0; numeric and duration store the value.
  RealColumn get value => real().withDefault(const Constant(1))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ParkedIdeas extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get whyTempting => text().nullable()();
  TextColumn get potentialValue => text().nullable()();
  TextColumn get dateCaptured => text()(); // yyyy-MM-dd
  TextColumn get reviewDate => text()(); // yyyy-MM-dd, captured + 7 days
  TextColumn get decision => text().withDefault(
      const Constant('undecided'))(); // undecided | ignore | later | integrate
  // SQL name predates the universal main-goal system; kept for data compat.
  BoolColumn get helpsMainGoal => boolean()
      .named('directly_helps_kaizen_this_week')
      .withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The user's one main goal — the outcome the app organizes itself around.
/// Exactly one row is `active` at a time; finished or shelved goals keep
/// their history with a different status.
@TableIndex(name: 'idx_main_goals_status', columns: {#status})
class MainGoals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();

  /// Why this goal matters, in the user's words. Optional.
  TextColumn get why => text().withDefault(const Constant(''))();
  TextColumn get targetDate => text().nullable()(); // yyyy-MM-dd
  // active | paused | completed | archived  (see MainGoalStatus)
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Milestones under the main goal (known as `goals` in storage for
/// historical reasons — pre-v2 these were free-standing "goals").
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get metricName => text().nullable()();
  RealColumn get currentValue => real().withDefault(const Constant(0))();
  RealColumn get targetValue => real().withDefault(const Constant(0))();
  TextColumn get targetDate => text().nullable()(); // yyyy-MM-dd
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class FreedomTargets extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  RealColumn get targetMonthlyPassiveIncome =>
      real().withDefault(const Constant(0))();
  RealColumn get targetLiquidNetWorth =>
      real().withDefault(const Constant(0))();
  RealColumn get currentMonthlyPassiveIncome =>
      real().withDefault(const Constant(0))();
  RealColumn get currentLiquidNetWorth =>
      real().withDefault(const Constant(0))();
  TextColumn get targetDate => text().nullable()(); // yyyy-MM-dd
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  // morningCommand | dailyAction | moneyCheck | nightReview | custom
  TextColumn get type => text().withDefault(const Constant('custom'))();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();

  /// Fires on these weekdays (bitmask, bit 0 = Monday). 127 = daily.
  /// Ignored when [oneShotDate] is set.
  IntColumn get weekdays => integer().withDefault(const Constant(127))();

  /// When set (yyyy-MM-dd), fires once on that date and is then disabled.
  TextColumn get oneShotDate => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  // Stable int id handed to the platform notification plugin.
  IntColumn get notificationId => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class IdentityStatements extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tracked financial accounts — bank, credit, investment, cash. Balances
/// are updated manually or by CSV import; every update writes a snapshot.
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  // checking | savings | credit | investment | cash | other (see AccountKind)
  TextColumn get kind => text().withDefault(const Constant('checking'))();

  /// Balance in integer cents.
  IntColumn get balanceCents => integer().withDefault(const Constant(0))();

  /// Credit balances count negative toward net worth when included.
  BoolColumn get includeInNetWorth =>
      boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Dated balance history per account (one snapshot per account per day).
@TableIndex(name: 'idx_balance_snapshots_account', columns: {#accountId})
class BalanceSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get date => text()(); // yyyy-MM-dd

  /// Balance in integer cents.
  IntColumn get balanceCents => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Monthly recurring expenses (rent, subscriptions). Materialized into
/// TransactionEntries once per month by RecurringService.
class RecurringTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable()();

  /// Amount in integer cents.
  IntColumn get amountCents => integer()();
  TextColumn get description => text().withDefault(const Constant(''))();

  /// 1–31; clamped to the month's last day when shorter.
  IntColumn get dayOfMonth => integer().withDefault(const Constant(1))();
  BoolColumn get isIntentional => boolean().withDefault(const Constant(true))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// yyyy-MM of the last month an entry was created for (idempotence).
  TextColumn get lastMaterializedMonth => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One guided weekly review per week (weekStart = Monday day key).
@TableIndex(name: 'idx_weekly_reviews_week', columns: {#weekStart})
class WeeklyReviews extends Table {
  TextColumn get id => text()();
  TextColumn get weekStart => text()(); // yyyy-MM-dd, Monday
  TextColumn get reflection => text().withDefault(const Constant(''))();
  TextColumn get emphasis => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Free-form journal lines. One row per entry; several entries per day
/// are fine — capture should cost seconds, not a blank-page ritual.
@TableIndex(name: 'idx_journal_entries_date', columns: {#date})
class JournalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Key-value settings that must survive export/import (income, surplus
/// targets, birthday, philosophy text, Roth IRA numbers, balances).
class SettingsEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  MainGoals,
  Accounts,
  BalanceSnapshots,
  RecurringTransactions,
  WeeklyReviews,
  GrowthMetrics,
  GrowthMetricEntries,
  DailyExperiments,
  BudgetCategories,
  TransactionEntries,
  TimeBudgets,
  TimeBlocks,
  Countdowns,
  Habits,
  HabitLogs,
  ParkedIdeas,
  Goals,
  FreedomTargets,
  Reminders,
  IdentityStatements,
  JournalEntries,
  SettingsEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: the universal main-goal system.
            await m.createTable(mainGoals);
            await m.addColumn(goals, goals.isDone);
            await m.addColumn(goals, goals.sortOrder);
            // Legacy value rewrites + deriving the main goal from existing
            // Kaizen-era data live in LegacyMigration (shared with import).
          }
          if (from < 3) {
            // v3: accounts, recurring expenses, weekly reviews, schedules.
            await m.createTable(accounts);
            await m.createTable(balanceSnapshots);
            await m.createTable(recurringTransactions);
            await m.createTable(weeklyReviews);
            await m.addColumn(transactionEntries, transactionEntries.accountId);
            await m.addColumn(
                transactionEntries, transactionEntries.sourceRecurringId);
            await m.addColumn(habits, habits.weekdays);
            await m.addColumn(habits, habits.reminderHour);
            await m.addColumn(habits, habits.reminderMinute);
            await m.addColumn(reminders, reminders.weekdays);
            await m.addColumn(reminders, reminders.oneShotDate);
            for (final index in allSchemaEntities.whereType<Index>()) {
              await m.createIndex(index);
            }
            // Turning the legacy manual balances into account rows lives in
            // LegacyMigration (shared with import).
          }
          if (from < 4) {
            // v4: money becomes integer cents so sums are exact, plus the
            // journal. alterTable recreates each table under the new
            // schema; the transformer converts the old REAL column
            // (referenced by its raw SQL name — it no longer exists in
            // the Dart schema) into cents.
            await m.alterTable(TableMigration(
              transactionEntries,
              columnTransformer: {
                transactionEntries.amountCents: const CustomExpression<int>(
                    'CAST(ROUND(amount * 100) AS INTEGER)'),
              },
            ));
            await m.alterTable(TableMigration(
              recurringTransactions,
              columnTransformer: {
                recurringTransactions.amountCents: const CustomExpression<int>(
                    'CAST(ROUND(amount * 100) AS INTEGER)'),
              },
            ));
            await m.alterTable(TableMigration(
              budgetCategories,
              columnTransformer: {
                budgetCategories.monthlyTargetCents:
                    const CustomExpression<int>(
                        'CAST(ROUND(monthly_target * 100) AS INTEGER)'),
              },
            ));
            await m.alterTable(TableMigration(
              accounts,
              columnTransformer: {
                accounts.balanceCents: const CustomExpression<int>(
                    'CAST(ROUND(balance * 100) AS INTEGER)'),
              },
            ));
            await m.alterTable(TableMigration(
              balanceSnapshots,
              columnTransformer: {
                balanceSnapshots.balanceCents: const CustomExpression<int>(
                    'CAST(ROUND(balance * 100) AS INTEGER)'),
              },
            ));
            await m.createTable(journalEntries);
            // Recreated tables lost their indexes; createIndex is
            // IF NOT EXISTS, so re-running the full set is safe.
            for (final index in allSchemaEntities.whereType<Index>()) {
              await m.createIndex(index);
            }
          }
        },
      );

  /// Wipes every table. Used by "Reset all data" and JSON import.
  Future<void> clearAllTables() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

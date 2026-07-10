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

class GrowthMetricEntries extends Table {
  TextColumn get id => text()();
  TextColumn get metricId => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  RealColumn get value => real()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

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
  RealColumn get monthlyTarget => real().withDefault(const Constant(0))();
  // none | warnOverTarget | warnOverZero | warnOverZeroUnlessIntentional |
  // criticalOverZero  (see BudgetFlagType)
  TextColumn get flagType => text().withDefault(const Constant('warnOverTarget'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable()(); // null = uncategorized fog
  TextColumn get date => text()(); // yyyy-MM-dd
  RealColumn get amount => real()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isIntentional => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class TimeBudgets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  // sleep | job | kaizen | admin | decompress | meals | exercise |
  // volunteering | toastmasters | meditation | other  (see TimeCategoryKind)
  TextColumn get kind => text().withDefault(const Constant('other'))();
  RealColumn get weeklyTargetHours => real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

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
  TextColumn get type => text().withDefault(const Constant('boolean'))(); // boolean | numeric | duration
  TextColumn get unit => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

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
  TextColumn get decision => text().withDefault(const Constant('undecided'))(); // undecided | ignore | later | integrate
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
  RealColumn get targetLiquidNetWorth => real().withDefault(const Constant(0))();
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
  // morningCommand | kaizenExperiment | moneyCheck | nightReview | custom
  TextColumn get type => text().withDefault(const Constant('custom'))();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
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
  SettingsEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

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

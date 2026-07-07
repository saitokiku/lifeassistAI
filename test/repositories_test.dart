import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/storage/seed_service.dart';
import 'package:life_dashboard/features/habits/data/habits_repository.dart';
import 'package:life_dashboard/features/ideas/data/ideas_repository.dart';
import 'package:life_dashboard/features/kaizen/data/kaizen_repository.dart';
import 'package:life_dashboard/features/money/data/money_repository.dart';
import 'package:life_dashboard/features/settings/data/backup_service.dart';
import 'package:life_dashboard/features/settings/data/settings_repository.dart';
import 'package:life_dashboard/features/time/data/time_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
  });

  tearDown(() async {
    await db.close();
  });

  group('SeedService', () {
    test('seeds defaults once and is idempotent', () async {
      final seed = SeedService(db);
      await seed.seedIfNeeded();
      await seed.seedIfNeeded(); // second run must not duplicate

      final categories = await db.select(db.budgetCategories).get();
      expect(categories, hasLength(12));
      expect(categories.map((c) => c.name), contains('Amazon'));

      final budgets = await db.select(db.timeBudgets).get();
      expect(budgets, hasLength(10));
      expect(
        budgets.firstWhere((b) => b.kind == 'kaizen').weeklyTargetHours,
        42,
      );

      final habits = await db.select(db.habits).get();
      expect(habits, hasLength(6));

      final reminders = await db.select(db.reminders).get();
      expect(reminders, hasLength(4));

      final metrics = await db.select(db.growthMetrics).get();
      expect(metrics.where((m) => m.isActive), hasLength(1));

      final settings = await SettingsRepository(db).getSettings();
      expect(settings.monthlyNetIncome, 6942);
      expect(settings.targetSurplusLow, 3200);
      expect(settings.targetSurplusHigh, 3800);
    });
  });

  group('KaizenRepository', () {
    test('metric CRUD, single-active rule, entry upsert', () async {
      final repo = KaizenRepository(db);
      final m1 = await repo.createMetric(
          name: 'Users', unit: 'users', weeklyTarget: 10, makeActive: true);
      final m2 = await repo.createMetric(
          name: 'Revenue', unit: r'$', weeklyTarget: 100);

      await repo.setActiveMetric(m2.id);
      final metrics = await db.select(db.growthMetrics).get();
      expect(metrics.where((m) => m.isActive).single.id, m2.id);

      // Entry upsert replaces same-day values and refreshes currentValue.
      await repo.upsertEntry(
          metricId: m1.id, date: DateTime(2026, 7, 7), value: 5);
      await repo.upsertEntry(
          metricId: m1.id, date: DateTime(2026, 7, 7), value: 8);
      final entries = await (db.select(db.growthMetricEntries)
            ..where((t) => t.metricId.equals(m1.id)))
          .get();
      expect(entries, hasLength(1));
      expect(entries.single.value, 8);
      final refreshed = await (db.select(db.growthMetrics)
            ..where((t) => t.id.equals(m1.id)))
          .getSingle();
      expect(refreshed.currentValue, 8);

      // Deleting a metric removes its entries.
      await repo.deleteMetric(m1.id);
      expect(
        await (db.select(db.growthMetricEntries)
              ..where((t) => t.metricId.equals(m1.id)))
            .get(),
        isEmpty,
      );
    });

    test('experiments persist and delete', () async {
      final repo = KaizenRepository(db);
      await repo.logExperiment(
        date: DateTime(2026, 7, 7),
        hypothesis: 'H',
        actionTaken: 'A',
        result: 'R',
        verdict: 'confirm',
      );
      final all = await db.select(db.dailyExperiments).get();
      expect(all, hasLength(1));
      await repo.deleteExperiment(all.single.id);
      expect(await db.select(db.dailyExperiments).get(), isEmpty);
    });
  });

  group('MoneyRepository', () {
    test('deleting a category detaches its transactions', () async {
      final repo = MoneyRepository(db);
      await repo.createCategory(
          name: 'Food', monthlyTarget: 400, flagType: 'warnOverTarget');
      final cat = (await db.select(db.budgetCategories).get()).single;
      await repo.addTransaction(
        date: DateTime(2026, 7, 7),
        amount: 25,
        description: 'lunch',
        categoryId: cat.id,
      );
      await repo.deleteCategory(cat.id);

      final txs = await db.select(db.transactionEntries).get();
      expect(txs.single.categoryId, isNull); // fog, not deleted
    });

    test('month filter only returns the current month', () async {
      final repo = MoneyRepository(db);
      await repo.addTransaction(
          date: DateTime(2026, 7, 7), amount: 10, description: 'in month');
      await repo.addTransaction(
          date: DateTime(2026, 6, 30), amount: 20, description: 'last month');
      final july = await repo.watchMonthTransactions(DateTime(2026, 7)).first;
      expect(july, hasLength(1));
      expect(july.single.description, 'in month');
    });
  });

  group('TimeRepository', () {
    test('week blocks filter by week and cascade on budget delete', () async {
      final repo = TimeRepository(db);
      await repo.createBudget(name: 'Kaizen', kind: 'kaizen', weeklyTargetHours: 42);
      final budget = (await db.select(db.timeBudgets).get()).single;

      await repo.logBlock(
          budgetId: budget.id, date: DateTime(2026, 7, 7), hours: 4);
      await repo.logBlock(
          budgetId: budget.id, date: DateTime(2026, 6, 20), hours: 3);

      final week = await repo.watchWeekBlocks(DateTime(2026, 7, 7)).first;
      expect(week, hasLength(1));
      expect(week.single.hours, 4);

      await repo.deleteBudget(budget.id);
      expect(await db.select(db.timeBlocks).get(), isEmpty);
    });
  });

  group('HabitsRepository', () {
    test('log upsert replaces same-day value; unlog removes', () async {
      final repo = HabitsRepository(db);
      await repo.createHabit(name: 'Meditation', type: 'duration', unit: 'min');
      final habit = (await db.select(db.habits).get()).single;

      final day = DateTime(2026, 7, 7);
      await repo.upsertLog(habitId: habit.id, date: day, value: 10);
      await repo.upsertLog(habitId: habit.id, date: day, value: 20);
      final logs = await db.select(db.habitLogs).get();
      expect(logs, hasLength(1));
      expect(logs.single.value, 20);

      await repo.removeLog(habitId: habit.id, date: day);
      expect(await db.select(db.habitLogs).get(), isEmpty);
    });
  });

  group('IdeasRepository', () {
    test('capture sets review date 7 days out', () async {
      final repo = IdeasRepository(db);
      await repo.captureIdea(
        title: 'Shiny thing',
        directlyHelpsKaizenThisWeek: false,
        capturedOn: DateTime(2026, 7, 7),
      );
      final idea = (await db.select(db.parkedIdeas).get()).single;
      expect(idea.dateCaptured, '2026-07-07');
      expect(idea.reviewDate, '2026-07-14');
      expect(idea.decision, 'undecided');
    });
  });

  group('BackupService', () {
    test('export/import round-trips all tables', () async {
      await SeedService(db).seedIfNeeded();
      final kaizen = KaizenRepository(db);
      final metric = (await db.select(db.growthMetrics).get()).single;
      await kaizen.upsertEntry(
          metricId: metric.id, date: DateTime(2026, 7, 7), value: 3);

      final backup = BackupService(db);
      final json = await backup.exportJson();

      // Wipe and import into the same schema.
      await db.clearAllTables();
      expect(await db.select(db.budgetCategories).get(), isEmpty);

      final result = await backup.importJson(json);
      expect(result.isSuccess, isTrue, reason: result.errorOrNull ?? '');

      expect(await db.select(db.budgetCategories).get(), hasLength(12));
      expect(await db.select(db.timeBudgets).get(), hasLength(10));
      expect(await db.select(db.growthMetricEntries).get(), hasLength(1));
      final settings = await SettingsRepository(db).getSettings();
      expect(settings.monthlyNetIncome, 6942);
    });

    test('rejects malformed JSON without touching data', () async {
      await SeedService(db).seedIfNeeded();
      final result = await BackupService(db).importJson('not json at all');
      expect(result.isSuccess, isFalse);
      expect(await db.select(db.budgetCategories).get(), hasLength(12));
    });
  });
}

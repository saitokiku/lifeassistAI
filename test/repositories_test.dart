import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/storage/seed_service.dart';
import 'package:life_dashboard/features/focus/data/focus_repository.dart';
import 'package:life_dashboard/features/habits/data/habits_repository.dart';
import 'package:life_dashboard/features/ideas/data/ideas_repository.dart';
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
    test('seeds neutral defaults once and is idempotent', () async {
      final seed = SeedService(db);
      await seed.seedIfNeeded();
      await seed.seedIfNeeded(); // second run must not duplicate

      final categories = await db.select(db.budgetCategories).get();
      expect(categories, hasLength(8));
      expect(categories.map((c) => c.name), contains('Groceries'));
      // Categories start unopinionated: no targets, no flag rules.
      expect(categories.every((c) => c.monthlyTarget == 0), isTrue);

      final budgets = await db.select(db.timeBudgets).get();
      expect(budgets, hasLength(6));
      expect(
        budgets.firstWhere((b) => b.kind == 'goal').weeklyTargetHours,
        10,
      );

      expect(await db.select(db.habits).get(), hasLength(3));
      expect(await db.select(db.reminders).get(), hasLength(3));
      expect(await db.select(db.countdowns).get(), hasLength(2));

      // No goal, metric, statements, or freedom target are pre-seeded —
      // those are the user's to define.
      expect(await db.select(db.mainGoals).get(), isEmpty);
      expect(await db.select(db.growthMetrics).get(), isEmpty);
      expect(await db.select(db.identityStatements).get(), isEmpty);
      expect(await db.select(db.freedomTargets).get(), isEmpty);

      final settings = await SettingsRepository(db).getSettings();
      expect(settings.monthlyNetIncome, 0);
      expect(settings.hasIncome, isFalse);
      expect(settings.philosophyText, isEmpty);
    });
  });

  group('FocusRepository — main goal', () {
    test('create/watch/status transitions, one open goal at a time', () async {
      final repo = FocusRepository(db);
      final first = await repo.createGoal(title: 'Kaizen', why: 'because');
      expect((await repo.watchCurrentGoal().first)!.id, first.id);

      await repo.setGoalStatus(first.id, 'paused');
      expect((await repo.watchCurrentGoal().first)!.status, 'paused');

      // A new goal archives the old one.
      final second = await repo.createGoal(title: 'Run a marathon');
      final current = await repo.watchCurrentGoal().first;
      expect(current!.id, second.id);
      final all = await repo.watchAllGoals().first;
      expect(all.firstWhere((g) => g.id == first.id).status, 'archived');

      // Completing removes it from "current" and stamps completedAt.
      await repo.setGoalStatus(second.id, 'completed');
      expect(await repo.watchCurrentGoal().first, isNull);
      final done = (await repo.watchAllGoals().first)
          .firstWhere((g) => g.id == second.id);
      expect(done.completedAt, isNotNull);
    });
  });

  group('FocusRepository — milestones', () {
    test('create, order, done state, delete', () async {
      final repo = FocusRepository(db);
      final a = await repo.createMilestone(title: 'Outline');
      final b = await repo.createMilestone(title: 'First draft');
      expect(a.sortOrder, 0);
      expect(b.sortOrder, 1);

      await repo.setMilestoneDone(a.id, true);
      final ordered = await repo.watchMilestones().first;
      // Undone milestones lead; done ones sink to the bottom.
      expect(ordered.first.id, b.id);
      expect(ordered.last.isDone, isTrue);

      await repo.deleteMilestone(a.id);
      expect(await repo.watchMilestones().first, hasLength(1));
    });
  });

  group('FocusRepository — measures & daily actions', () {
    test('metric CRUD, single-active rule, entry upsert', () async {
      final repo = FocusRepository(db);
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

    test('daily actions persist and delete', () async {
      final repo = FocusRepository(db);
      await repo.logAction(
        date: DateTime(2026, 7, 7),
        hypothesis: 'H',
        actionTaken: 'A',
        result: 'R',
        verdict: 'confirm',
      );
      final all = await db.select(db.dailyExperiments).get();
      expect(all, hasLength(1));
      await repo.deleteAction(all.single.id);
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
      expect(txs.single.categoryId, isNull); // uncategorized, not deleted
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

    test('transactions since a date, oldest first (history chart)', () async {
      final repo = MoneyRepository(db);
      await repo.addTransaction(
          date: DateTime(2026, 7, 7), amount: 10, description: 'jul');
      await repo.addTransaction(
          date: DateTime(2026, 5, 1), amount: 20, description: 'may');
      await repo.addTransaction(
          date: DateTime(2026, 2, 1), amount: 30, description: 'feb');
      final since = await repo.watchTransactionsSince(DateTime(2026, 5)).first;
      expect(since.map((t) => t.description), ['may', 'jul']);
    });
  });

  group('TimeRepository', () {
    test('week blocks filter by week and cascade on budget delete', () async {
      final repo = TimeRepository(db);
      await repo.createBudget(
          name: 'Main goal', kind: 'goal', weeklyTargetHours: 10);
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

    test('blocks since a date, oldest first (history chart)', () async {
      final repo = TimeRepository(db);
      await repo.createBudget(
          name: 'Main goal', kind: 'goal', weeklyTargetHours: 10);
      final budget = (await db.select(db.timeBudgets).get()).single;

      await repo.logBlock(
          budgetId: budget.id, date: DateTime(2026, 7, 7), hours: 4);
      await repo.logBlock(
          budgetId: budget.id, date: DateTime(2026, 6, 1), hours: 3);
      await repo.logBlock(
          budgetId: budget.id, date: DateTime(2026, 4, 1), hours: 2);

      final since = await repo.watchBlocksSince(DateTime(2026, 6)).first;
      expect(since.map((b) => b.hours), [3, 4]);
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
        helpsMainGoal: false,
        capturedOn: DateTime(2026, 7, 7),
      );
      final idea = (await db.select(db.parkedIdeas).get()).single;
      expect(idea.dateCaptured, '2026-07-07');
      expect(idea.reviewDate, '2026-07-14');
      expect(idea.decision, 'undecided');
    });
  });

  group('BackupService', () {
    test('export/import round-trips all tables including the goal', () async {
      await SeedService(db).seedIfNeeded();
      final focus = FocusRepository(db);
      await focus.createGoal(title: 'Kaizen', why: 'compounding');
      await focus.createMilestone(title: 'First milestone');
      final metric = await focus.createMetric(
          name: 'Learners', unit: 'users', weeklyTarget: 10, makeActive: true);
      await focus.upsertEntry(
          metricId: metric.id, date: DateTime(2026, 7, 7), value: 3);

      final backup = BackupService(db);
      final json = await backup.exportJson();

      // Wipe and import into the same schema.
      await db.clearAllTables();
      expect(await db.select(db.budgetCategories).get(), isEmpty);

      final result = await backup.importJson(json);
      expect(result.isSuccess, isTrue, reason: result.errorOrNull ?? '');

      expect(await db.select(db.budgetCategories).get(), hasLength(8));
      expect(await db.select(db.timeBudgets).get(), hasLength(6));
      expect(await db.select(db.growthMetricEntries).get(), hasLength(1));
      final goal = (await db.select(db.mainGoals).get()).single;
      expect(goal.title, 'Kaizen');
      expect(goal.why, 'compounding');
      expect(await db.select(db.goals).get(), hasLength(1));
    });

    test('rejects malformed JSON without touching data', () async {
      await SeedService(db).seedIfNeeded();
      final result = await BackupService(db).importJson('not json at all');
      expect(result.isSuccess, isFalse);
      expect(await db.select(db.budgetCategories).get(), hasLength(8));
    });
  });
}

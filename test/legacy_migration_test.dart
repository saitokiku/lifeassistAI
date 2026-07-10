import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/storage/legacy_migration.dart';
import 'package:life_dashboard/features/settings/data/backup_service.dart';

/// The universal main-goal redesign must not lose a single row of the
/// original Kaizen-era data. These tests plant pre-v2-shaped data and prove
/// it comes out the other side as the user's own "Kaizen" goal.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
  });

  tearDown(() async {
    await db.close();
  });

  final at = DateTime(2026, 7, 1);

  Future<void> plantKaizenEraData() async {
    // The v1 seed always created one active growth metric; a real user also
    // has experiments, a kaizen time budget, and a kaizen reminder.
    await db.into(db.growthMetrics).insert(GrowthMetric(
          id: 'metric-1',
          name: 'Weekly active learners',
          unit: 'users',
          currentValue: 12,
          weeklyTarget: 10,
          isActive: true,
          createdAt: at,
          updatedAt: at,
        ));
    await db.into(db.dailyExperiments).insert(DailyExperiment(
          id: 'exp-1',
          date: '2026-06-30',
          hypothesis: 'H',
          actionTaken: 'A',
          result: 'R',
          verdict: 'confirm',
          notes: null,
          createdAt: at,
          updatedAt: at,
        ));
    await db.into(db.timeBudgets).insert(const TimeBudget(
          id: 'budget-1',
          name: 'Kaizen',
          kind: 'kaizen',
          weeklyTargetHours: 42,
          sortOrder: 0,
        ));
    await db.into(db.reminders).insert(Reminder(
          id: 'rem-1',
          title: 'Kaizen experiment',
          message: '',
          type: 'kaizenExperiment',
          hour: 12,
          minute: 0,
          enabled: true,
          notificationId: 1,
          createdAt: at,
          updatedAt: at,
        ));
  }

  group('LegacyMigration', () {
    test('rewrites kaizen-era enum values and derives the Kaizen goal',
        () async {
      await plantKaizenEraData();

      await LegacyMigration(db).run(now: at);

      final budget = (await db.select(db.timeBudgets).get()).single;
      expect(budget.kind, 'goal');
      expect(budget.name, 'Kaizen'); // user-visible name is user data — kept

      final reminder = (await db.select(db.reminders).get()).single;
      expect(reminder.type, 'dailyAction');
      expect(reminder.title, 'Kaizen experiment'); // user data — kept

      final goal = (await db.select(db.mainGoals).get()).single;
      expect(goal.title, 'Kaizen');
      expect(goal.status, 'active');

      // Every original row survives.
      expect(await db.select(db.growthMetrics).get(), hasLength(1));
      expect(await db.select(db.dailyExperiments).get(), hasLength(1));
    });

    test('is idempotent', () async {
      await plantKaizenEraData();
      await LegacyMigration(db).run(now: at);
      await LegacyMigration(db).run(now: at);
      expect(await db.select(db.mainGoals).get(), hasLength(1));
    });

    test('does nothing on a fresh database', () async {
      await LegacyMigration(db).run(now: at);
      expect(await db.select(db.mainGoals).get(), isEmpty);
    });

    test('never overwrites a goal the user already set', () async {
      await plantKaizenEraData();
      await db.into(db.mainGoals).insert(MainGoal(
            id: 'goal-1',
            title: 'My own goal',
            why: '',
            targetDate: null,
            status: 'active',
            createdAt: at,
            updatedAt: at,
            completedAt: null,
          ));
      await LegacyMigration(db).run(now: at);
      final goals = await db.select(db.mainGoals).get();
      expect(goals, hasLength(1));
      expect(goals.single.title, 'My own goal');
    });
  });

  group('v1 backup import', () {
    /// A trimmed but shape-accurate v1 export: pre-v2 JSON keys, kaizen
    /// enum values, no mainGoals section, goals without isDone/sortOrder.
    String v1Envelope() => jsonEncode({
          'app': 'Life Dashboard',
          'schemaVersion': '1',
          'exportedAt': '2026-06-30T12:00:00.000',
          'data': {
            'settings': [
              {'key': 'monthlyNetIncome', 'value': '6942.0'},
              {'key': 'philosophyText', 'value': 'My line'},
            ],
            'growthMetrics': [
              {
                'id': 'metric-1',
                'name': 'Weekly active learners',
                'unit': 'users',
                'currentValue': 12.0,
                'weeklyTarget': 10.0,
                'isActive': true,
                'createdAt': at.millisecondsSinceEpoch,
                'updatedAt': at.millisecondsSinceEpoch,
              },
            ],
            'timeBudgets': [
              {
                'id': 'budget-1',
                'name': 'Kaizen',
                'kind': 'kaizen',
                'weeklyTargetHours': 42.0,
                'sortOrder': 0,
              },
            ],
            'parkedIdeas': [
              {
                'id': 'idea-1',
                'title': 'Old idea',
                'description': null,
                'category': null,
                'whyTempting': null,
                'potentialValue': null,
                'dateCaptured': '2026-06-20',
                'reviewDate': '2026-06-27',
                'decision': 'undecided',
                'directlyHelpsKaizenThisWeek': true,
                'createdAt': at.millisecondsSinceEpoch,
                'updatedAt': at.millisecondsSinceEpoch,
              },
            ],
            'goals': [
              {
                'id': 'goal-row-1',
                'title': 'Ship the beta',
                'description': null,
                'metricName': 'users',
                'currentValue': 4.0,
                'targetValue': 10.0,
                'targetDate': null,
                'createdAt': at.millisecondsSinceEpoch,
                'updatedAt': at.millisecondsSinceEpoch,
              },
            ],
            'reminders': [
              {
                'id': 'rem-1',
                'title': 'Kaizen experiment',
                'message': '',
                'type': 'kaizenExperiment',
                'hour': 12,
                'minute': 0,
                'enabled': true,
                'notificationId': 1,
                'createdAt': at.millisecondsSinceEpoch,
                'updatedAt': at.millisecondsSinceEpoch,
              },
            ],
          },
        });

    test('normalizes a pre-v2 envelope and derives the Kaizen goal',
        () async {
      final result = await BackupService(db).importJson(v1Envelope());
      expect(result.isSuccess, isTrue, reason: result.errorOrNull ?? '');

      // The old idea's Kaizen flag becomes the goal flag.
      final idea = (await db.select(db.parkedIdeas).get()).single;
      expect(idea.helpsMainGoal, isTrue);

      // Old goals become milestones with sane defaults.
      final milestone = (await db.select(db.goals).get()).single;
      expect(milestone.title, 'Ship the beta');
      expect(milestone.isDone, isFalse);

      // Enum values are rewritten and the goal is derived.
      expect((await db.select(db.timeBudgets).get()).single.kind, 'goal');
      expect(
          (await db.select(db.reminders).get()).single.type, 'dailyAction');
      final goal = (await db.select(db.mainGoals).get()).single;
      expect(goal.title, 'Kaizen');

      // Data itself is intact.
      final metric = (await db.select(db.growthMetrics).get()).single;
      expect(metric.name, 'Weekly active learners');
      expect(metric.currentValue, 12);
    });
  });
}

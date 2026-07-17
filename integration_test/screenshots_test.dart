import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_dashboard/app.dart';
import 'package:life_dashboard/core/providers.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/storage/preferences_service.dart';
import 'package:life_dashboard/core/storage/seed_service.dart';
import 'package:life_dashboard/core/utils/date_utils.dart';
import 'package:life_dashboard/features/notes/data/notes_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Store screenshot run: boots the real app against a seeded demo
/// database and captures the six listing shots. Drive it with
/// `flutter drive --driver=test_driver/integration_test.dart
/// --target=integration_test/screenshots_test.dart -d SIM_UDID`.
/// PNGs land in screenshots/ via the driver (see docs/app_store_listing.md).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await settle(tester);
    await binding.takeScreenshot(name);
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    ));
    await settle(tester);
  }

  testWidgets('capture App Store screenshots', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboardingComplete': true,
      'launchDiscoveryDismissed': true,
    });
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    await SeedService(db).seedIfNeeded();
    await _seedDemo(db);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        preferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
      ],
      child: const LifeDashboardApp(),
    ));
    await settle(tester);
    await settle(tester);

    await shoot(tester, '01-today');

    await tapTab(tester, 'Focus');
    await shoot(tester, '02-focus');

    await tapTab(tester, 'Money');
    await shoot(tester, '03-money');

    await tapTab(tester, 'Time');
    await shoot(tester, '04-time');

    // You → Notes list → Graph.
    await tapTab(tester, 'You');
    await tester.scrollUntilVisible(
      find.text('Notes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Notes').first);
    await settle(tester);
    await shoot(tester, '05-notes');

    await tester.tap(find.byTooltip('Graph'));
    await settle(tester);
    await shoot(tester, '06-graph');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

/// Believable demo content on top of the neutral seeds: a live goal
/// with milestones and a moving metric, money with real-looking spend,
/// a filled week of time, checked habits, and a linked Zettelkasten
/// whose graph photographs well.
Future<void> _seedDemo(AppDatabase db) async {
  final now = DateTime.now();
  final today = AppDateUtils.dateKey(now);
  String daysAgo(int n) =>
      AppDateUtils.dateKey(now.subtract(Duration(days: n)));

  await db.batch((b) {
    b.insertAll(db.settingsEntries, const [
      SettingsEntry(key: 'displayName', value: 'Alex'),
      SettingsEntry(key: 'monthlyNetIncome', value: '6200'),
    ]);

    b.insertAll(db.mainGoals, [
      MainGoal(
        id: 'demo-goal',
        title: 'Launch the studio',
        why: 'Work I own, on work that matters.',
        targetDate: AppDateUtils.dateKey(now.add(const Duration(days: 90))),
        status: 'active',
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now,
        completedAt: null,
      ),
    ]);

    b.insertAll(db.goals, [
      Goal(
        id: 'demo-m1',
        title: 'Ship the portfolio site',
        description: null,
        metricName: null,
        currentValue: 0,
        targetValue: 0,
        targetDate: null,
        isDone: true,
        sortOrder: 0,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      Goal(
        id: 'demo-m2',
        title: 'First three client calls',
        description: null,
        metricName: null,
        currentValue: 0,
        targetValue: 0,
        targetDate: null,
        isDone: false,
        sortOrder: 1,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      ),
      Goal(
        id: 'demo-m3',
        title: 'Sign the first retainer',
        description: null,
        metricName: null,
        currentValue: 0,
        targetValue: 0,
        targetDate: null,
        isDone: false,
        sortOrder: 2,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      ),
    ]);

    b.insertAll(db.growthMetrics, [
      GrowthMetric(
        id: 'demo-metric',
        name: 'Deep work hours',
        unit: 'h/week',
        currentValue: 14,
        weeklyTarget: 15,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 42)),
        updatedAt: now,
      ),
    ]);
    b.insertAll(db.growthMetricEntries, [
      for (final (i, v) in const [6.0, 8.5, 9.0, 11.5, 12.0, 14.0].indexed)
        GrowthMetricEntry(
          id: 'demo-me-$i',
          metricId: 'demo-metric',
          date: daysAgo((5 - i) * 7),
          value: v,
          note: null,
        ),
    ]);
  });

  // Money: give the seeded neutral categories targets + this-month spend.
  final categories = await db.select(db.budgetCategories).get();
  String catId(String name) => categories
      .firstWhere((c) => c.name == name, orElse: () => categories.first)
      .id;
  await db.batch((b) {
    for (final (name, cents) in const [
      ('Groceries', 45000),
      ('Rent', 165000),
      ('Eating out', 20000),
      ('Transport', 12000),
    ]) {
      b.update(
        db.budgetCategories,
        BudgetCategoriesCompanion(monthlyTargetCents: Value(cents)),
        where: (t) => t.name.equals(name),
      );
    }
    b.insertAll(db.accounts, [
      Account(
        id: 'demo-acct-1',
        name: 'Checking',
        kind: 'checking',
        balanceCents: 412350,
        includeInNetWorth: true,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
      Account(
        id: 'demo-acct-2',
        name: 'Savings',
        kind: 'savings',
        balanceCents: 1250000,
        includeInNetWorth: true,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    b.insertAll(db.transactionEntries, [
      for (final (i, t) in [
        (2, 'Farmers market', 6425, 'Groceries'),
        (3, 'Monthly rent', 165000, 'Rent'),
        (4, 'Ramen with Sam', 3180, 'Eating out'),
        (5, 'Metro card', 3300, 'Transport'),
        (6, 'Groceries', 8940, 'Groceries'),
        (8, 'Coffee beans', 1850, 'Groceries'),
      ].indexed)
        TransactionEntry(
          id: 'demo-tx-$i',
          categoryId: catId(t.$4),
          accountId: 'demo-acct-1',
          sourceRecurringId: null,
          date: daysAgo(t.$1),
          amountCents: t.$3,
          description: t.$2,
          isIntentional: true,
          createdAt: now,
        ),
    ]);
  });

  // Time: fill this week against the seeded budgets.
  final budgets = await db.select(db.timeBudgets).get();
  String budgetId(String kind) => budgets
      .firstWhere((b) => b.kind == kind, orElse: () => budgets.first)
      .id;
  await db.batch((b) {
    b.insertAll(db.timeBlocks, [
      for (final (i, t) in [
        (0, 'goal', 2.5, 'Client proposal'),
        (0, 'exercise', 1.0, 'Morning run'),
        (1, 'goal', 3.0, 'Deep work: brand system'),
        (1, 'admin', 0.5, null),
        (2, 'goal', 2.0, 'Portfolio case study'),
        (2, 'decompress', 1.5, null),
      ].indexed)
        TimeBlock(
          id: 'demo-tb-$i',
          budgetId: budgetId(t.$2),
          date: daysAgo(t.$1),
          hours: t.$3,
          note: t.$4,
          createdAt: now,
        ),
    ]);
  });

  // Habits: check a couple off today so the strip looks alive.
  final habits = await db.select(db.habits).get();
  await db.batch((b) {
    b.insertAll(db.habitLogs, [
      for (final (i, h) in habits.take(2).indexed)
        HabitLog(
          id: 'demo-hl-$i',
          habitId: h.id,
          date: today,
          value: 1,
          note: null,
          source: 'manual',
        ),
    ]);
    b.insertAll(db.journalEntries, [
      JournalEntry(
        id: 'demo-j1',
        date: today,
        content: 'Proposal out the door. Lighter already.',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  });

  // The Zettelkasten: a small constellation that photographs well.
  final notes = NotesRepository(db);
  await notes.createNote(
    title: 'Studio launch',
    content: 'The thesis: [[Positioning]] before portfolio. '
        'Ship weekly, write monthly.\n\n#studio',
  );
  await notes.createNote(
    title: 'Positioning',
    content: 'Narrow beats broad. See [[Pricing]] and '
        '[[First clients]].\n\n#studio #strategy',
  );
  await notes.createNote(
    title: 'Pricing',
    content: 'Value-based, three tiers. [[Positioning]] decides the '
        'anchor.\n\n#strategy',
  );
  await notes.createNote(
    title: 'First clients',
    content: 'Warm intros first: [[Studio launch]] list. '
        'Follow up in threes.\n\n#studio',
  );
  await notes.createNote(
    title: 'Deep work',
    content: 'Guard the mornings. Feeds [[Studio launch]] directly.\n\n'
        '#craft',
  );
}

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/app.dart';
import 'package:life_dashboard/core/providers.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/storage/legacy_migration.dart';
import 'package:life_dashboard/core/storage/preferences_service.dart';
import 'package:life_dashboard/core/storage/seed_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end smoke: the real app against a seeded in-memory database.
/// Every screen must build and the core paths — navigation, goal setup,
/// onboarding, legacy migration — must work at phone dimensions without
/// exceptions or layout overflows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  Future<Widget> appWith({
    required bool onboarded,
    Future<void> Function(AppDatabase db)? prepare,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (onboarded) 'onboardingComplete': true,
    });
    PackageInfo.setMockInitialValues(
      appName: 'Life Assist',
      packageName: 'com.kaizen.lifedashboard',
      version: '0.2.0',
      buildNumber: '2',
      buildSignature: '',
    );
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    if (prepare != null) await prepare(db);
    await SeedService(db).seedIfNeeded();
    await LegacyMigration(db).run();

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        preferencesProvider.overrideWithValue(prefs),
        // Fixed clock: no periodic timer pending at the end of the test.
        clockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
      ],
      child: const LifeDashboardApp(),
    );
  }

  Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for $finder');
  }

  Future<void> settle(WidgetTester tester) async {
    // Entrance animations run up to ~600ms; plain pumps avoid fighting
    // repeating shimmer controllers that pumpAndSettle can't outwait.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    ));
    await settle(tester);
  }

  Future<void> openHubRow(WidgetTester tester, String label) async {
    // Hub rows can sit below the fold (and outside the lazy ListView's
    // build window) on a phone-sized You screen — scroll with a plain
    // finder, which tolerates zero matches while off-screen.
    await tester.scrollUntilVisible(
      find.text(label),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(label).first);
    await settle(tester);
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Back').first);
    await settle(tester);
  }

  /// Drift schedules zero-duration timers when its query streams close.
  /// Unmount the app inside the test body so those timers can flush before
  /// the framework's pending-timer check runs.
  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('every screen builds and core navigation works on a phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(await appWith(onboarded: true));

    // Today: greeting, the Up-next hero inviting goal setup, check-in.
    await pumpUntil(tester, find.text('UP NEXT'));
    await settle(tester);
    expect(find.text('Set your main goal'), findsOneWidget);
    expect(find.text('CHECK-IN'), findsOneWidget);

    // Quick add opens and offers the captures that exist right now.
    await tester.tap(find.byType(FloatingActionButton).first);
    await settle(tester);
    expect(find.text('Quick add'), findsOneWidget);
    expect(find.text('Log time'), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);
    expect(find.text('Park an idea'), findsOneWidget);
    // No goal yet → no goal-step capture.
    expect(find.text('Goal step'), findsNothing);
    await tester.tapAt(const Offset(195, 60)); // dismiss via barrier
    await settle(tester);

    // Focus: invites the user to set a goal, then shows it.
    await tapTab(tester, 'Focus');
    expect(find.text('What are you working toward?'), findsOneWidget);
    await tester.tap(find.text('Set your main goal'));
    await settle(tester);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal'), 'Kaizen');
    await tester.tap(find.text('Set goal'));
    await settle(tester);
    expect(find.text('MAIN GOAL'), findsOneWidget);
    expect(find.text('Kaizen'), findsWidgets);
    expect(find.text('MILESTONES'), findsOneWidget);

    // Money: no income yet → setup invitation, budgets still reachable.
    await tapTab(tester, 'Money');
    expect(find.text('Where the month stands.'), findsOneWidget);
    expect(find.text('Set income'), findsOneWidget);
    expect(find.text('BUDGET CATEGORIES'), findsOneWidget);

    await tapTab(tester, 'Time');
    expect(find.text('Your week, in hours.'), findsOneWidget);

    await tapTab(tester, 'You');
    expect(find.text('Principles, systems, and settings.'), findsOneWidget);

    // You hub → each sub-screen and back.
    await openHubRow(tester, 'Habits');
    expect(find.text('Small daily supports.'), findsOneWidget);
    await goBack(tester);

    await openHubRow(tester, 'Ideas');
    expect(find.text('Catch ideas now, decide later.'), findsOneWidget);
    await goBack(tester);

    await openHubRow(tester, 'Reminders');
    expect(find.text('Gentle nudges through the day.'), findsOneWidget);
    await goBack(tester);

    // Notes: write the first note through the editor, render the
    // preview (wiki link + tag), and see it counted on the list.
    await openHubRow(tester, 'Notes');
    expect(find.text('Your vault is empty'), findsOneWidget);
    await tester.tap(find.text('First note'));
    await settle(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Title'), 'Deep Work');
    await tester.enterText(
        find.byType(TextField).last, 'Read [[Atomic Habits]] daily. #habit');
    await tester.tap(find.byTooltip('Preview'));
    await settle(tester);
    expect(find.text('Deep Work'), findsWidgets);
    expect(find.text('Atomic Habits'), findsOneWidget); // tappable link
    // Inline in the markdown AND as a chip in the tags row below.
    expect(find.text('#habit'), findsNWidgets(2));
    await goBack(tester);
    expect(find.text('1 note · 1 link'), findsOneWidget);
    await goBack(tester);

    await openHubRow(tester, 'Settings');
    expect(find.text('Targets, appearance, and your data.'), findsOneWidget);
    await goBack(tester);

    // Back on the hub (its list kept the scrolled position); Today now
    // reflects the goal set earlier.
    expect(find.text('SYSTEMS'), findsOneWidget);
    await tapTab(tester, 'Today');
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('Set your main goal'), findsNothing);
    // The goal snapshot card sits further down the Today list.
    await tester.scrollUntilVisible(
      find.text('KAIZEN'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('KAIZEN'), findsOneWidget); // goal snapshot card

    await shutDown(tester);
  });

  testWidgets('onboarding sets the goal and lands on a personalized Today',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(await appWith(onboarded: false));

    // Welcome.
    await pumpUntil(tester, find.text('One quiet place to run your life.'));
    await settle(tester);
    await tester.tap(find.text('Get started'));
    await settle(tester);

    // Goal step: pick an example, refine nothing, move on.
    expect(find.text('What are you working toward?'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget); // empty → skippable
    await tester.tap(find.text('Run a marathon'));
    await settle(tester);
    expect(find.text('Next'), findsOneWidget); // filled → Next
    await tester.tap(find.text('Next'));
    await settle(tester);

    // About you.
    expect(find.text('About you'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Your name (optional)'), 'Alex');
    await tester.tap(find.text('Next'));
    await settle(tester);

    // Rhythm: switch notifications off (no platform plugin in tests).
    expect(find.text('A light daily rhythm'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    await tester.tap(find.text('Start'));
    await settle(tester);

    // Lands on Today, greeting by name, goal live everywhere.
    await pumpUntil(tester, find.text('UP NEXT'));
    await settle(tester);
    expect(find.textContaining('Alex'), findsWidgets);
    expect(find.textContaining('Run a marathon'), findsWidgets);

    // The goal exists in storage.
    final goals = await db.select(db.mainGoals).get();
    expect(goals.single.title, 'Run a marathon');

    await shutDown(tester);
  });

  testWidgets('a Kaizen-era database arrives as the user\'s main goal',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final at = DateTime(2026, 6, 1);
    await tester.pumpWidget(await appWith(
      onboarded: true,
      prepare: (db) async {
        // Pre-v2 data: a growth metric, an experiment, a kaizen budget.
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
              hypothesis: 'Try a new landing page',
              actionTaken: 'Shipped it',
              result: 'Signups doubled',
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
      },
    ));

    await pumpUntil(tester, find.text('UP NEXT'));
    await settle(tester);

    // The Focus tab carries the migrated goal and all its history.
    await tapTab(tester, 'Focus');
    expect(find.text('MAIN GOAL'), findsOneWidget);
    expect(find.text('Kaizen'), findsWidgets);

    // The measure and the logged step live further down the screen.
    await tester.scrollUntilVisible(
      find.textContaining('Shipped it'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('WEEKLY ACTIVE LEARNERS'), findsOneWidget);
    expect(find.textContaining('Shipped it'), findsOneWidget);

    await shutDown(tester);
  });
}

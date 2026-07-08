import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/app.dart';
import 'package:life_dashboard/core/providers.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/storage/preferences_service.dart';
import 'package:life_dashboard/core/storage/seed_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end smoke: the real app against a seeded in-memory database.
/// Every screen must build and the core navigation paths must work at
/// phone dimensions without exceptions or layout overflows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  Future<Widget> appWith({required bool onboarded}) async {
    SharedPreferences.setMockInitialValues({
      if (onboarded) 'onboardingComplete': true,
    });
    PackageInfo.setMockInitialValues(
      appName: 'Life Dashboard',
      packageName: 'com.kaizen.lifedashboard',
      version: '0.2.0',
      buildNumber: '2',
      buildSignature: '',
    );
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    await SeedService(db).seedIfNeeded();

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

    // Today: greeting, focus hero, check-in, scoreboard.
    await pumpUntil(tester, find.text("TODAY'S FOCUS"));
    await settle(tester);
    expect(find.text('CHECK-IN'), findsOneWidget);
    expect(find.text('SCOREBOARD'), findsOneWidget);

    // Quick add opens and offers the five captures.
    await tester.tap(find.byType(FloatingActionButton).first);
    await settle(tester);
    expect(find.text('Quick add'), findsOneWidget);
    expect(find.text('Log time'), findsOneWidget);
    expect(find.text('Park an idea'), findsOneWidget);
    await tester.tapAt(const Offset(195, 60)); // dismiss via barrier
    await settle(tester);

    // Main tabs.
    await tapTab(tester, 'Kaizen');
    expect(find.text('One hunt. One test a day.'), findsOneWidget);

    await tapTab(tester, 'Money');
    expect(find.text('The scoreboard, not the mission.'), findsOneWidget);

    await tapTab(tester, 'Time');
    expect(find.text('Available time is the real budget.'), findsOneWidget);

    await tapTab(tester, 'You');
    expect(find.text('Direction, systems, and settings.'), findsOneWidget);

    // You hub → each sub-screen and back.
    await openHubRow(tester, 'Habits');
    expect(find.text('Support systems, not the mission.'), findsOneWidget);
    await goBack(tester);

    await openHubRow(tester, 'Ideas');
    expect(find.text('Curiosity captured. Not chased.'), findsOneWidget);
    await goBack(tester);

    await openHubRow(tester, 'Reminders');
    expect(
        find.text('The rhythm holds the system together.'), findsOneWidget);
    await goBack(tester);

    await openHubRow(tester, 'Settings');
    expect(find.text('Targets, appearance, and your data.'), findsOneWidget);
    await goBack(tester);

    await openHubRow(tester, 'Identity & direction');
    expect(find.text('The why behind the numbers.'), findsOneWidget);
    await goBack(tester);

    // Back on the hub, and Today is still alive in its branch.
    expect(find.text('Direction, systems, and settings.'), findsOneWidget);
    await tapTab(tester, 'Today');
    expect(find.text("TODAY'S FOCUS"), findsOneWidget);

    await shutDown(tester);
  });

  testWidgets('first run lands on onboarding and can advance',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(await appWith(onboarded: false));

    await pumpUntil(tester, find.textContaining('Money'));
    await settle(tester);

    // Page 1 → 2 via Next; a Back affordance appears.
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Back'), findsOneWidget);

    await shutDown(tester);
  });
}

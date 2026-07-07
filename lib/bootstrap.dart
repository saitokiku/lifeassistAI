import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/storage/app_database.dart';
import 'core/storage/database_connection.dart';
import 'core/storage/preferences_service.dart';
import 'core/storage/seed_service.dart';

/// Initializes storage, seeds first-launch defaults, and runs the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase(openAppDatabaseConnection());
  final preferences = await PreferencesService.create();

  // Seed defaults into empty tables. Safe to call every launch.
  await SeedService(database).seedIfNeeded();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        preferencesProvider.overrideWithValue(preferences),
      ],
      child: const LifeDashboardApp(),
    ),
  );
}

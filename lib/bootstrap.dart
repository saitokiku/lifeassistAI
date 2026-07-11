import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/native/bridge_paths.dart';
import 'core/native/capture_queue_drain.dart';
import 'core/native/entity_mirror_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/reminder_scheduler.dart';
import 'core/providers.dart';
import 'core/storage/app_database.dart';
import 'core/storage/database_connection.dart';
import 'core/storage/legacy_migration.dart';
import 'core/storage/preferences_service.dart';
import 'core/storage/seed_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/settings_repository.dart';

/// Initializes storage, seeds first-launch defaults, and runs the app.
///
/// If storage init fails (e.g. web without `sqlite3.wasm`), we render a
/// readable error instead of a blank screen — a silent white void is never
/// an acceptable failure mode.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final database = AppDatabase(openAppDatabaseConnection());
    final preferences = await PreferencesService.create();

    // Seeding and legacy migration are idempotent but not free (~a dozen
    // queries). Run them only when the data revision moved — reset and
    // backup import clear the flag so both re-run on the next launch.
    if (preferences.dataRevision != AppConstants.dataRevision) {
      // Seed defaults into empty tables.
      await SeedService(database).seedIfNeeded();
      // Rewrite older data into the current shape.
      await LegacyMigration(database).run();
      await preferences.setDataRevision(AppConstants.dataRevision);
    }

    // Snapshot this month's income once so surplus history stays honest
    // even if the configured income changes later. Write-free after the
    // first launch of each month.
    await SettingsRepository(database).ensureIncomeSnapshot();

    // The Swift bridge: mirror the app's nouns for Siri's entity queries
    // and drain any captures Siri wrote while the engine was down. Web
    // has neither a filesystem contract nor Siri.
    BridgePaths? bridge;
    EntityMirrorService? mirror;
    if (!kIsWeb) {
      bridge = await BridgePaths.resolve();
      mirror = EntityMirrorService(database, bridge);
      await mirror.start();
      final drain = CaptureQueueDrain(database, bridge);
      final result = await drain.drain();
      // Reminders captured by voice need their OS schedule reconciled the
      // moment we can (Swift already armed a provisional notification).
      if ((result.remindersChanged ||
              result.cancelNotificationIds.isNotEmpty) &&
          preferences.notificationsEnabled) {
        final notifications = NotificationService();
        await notifications.cancelMany(result.cancelNotificationIds);
        final reminders = await database.select(database.reminders).get();
        await ReminderScheduler(notifications)
            .syncAll(reminders, appEnabled: true);
      }
    }

    runApp(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          preferencesProvider.overrideWithValue(preferences),
          if (bridge != null) bridgePathsProvider.overrideWithValue(bridge),
          if (mirror != null) entityMirrorProvider.overrideWithValue(mirror),
        ],
        child: const LifeDashboardApp(),
      ),
    );
  } catch (error, stack) {
    debugPrint('Bootstrap failed: $error\n$stack');
    runApp(_BootstrapErrorApp(error: error));
  }
}

/// Minimal standalone app shown when storage can't initialize.
class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storage_rounded, size: 44),
                const SizedBox(height: 16),
                Text(
                  "Storage didn't start.",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The local database could not be opened, so the app '
                  "couldn't launch. On the web build this usually means "
                  '`web/sqlite3.wasm` is missing.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/native/bridge_paths.dart';
import 'core/native/capture_queue_drain.dart';
import 'core/native/entity_mirror_service.dart';
import 'core/native/live_activity_service.dart';
import 'core/notifications/notification_reconciler.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/reminder_scheduler.dart';
import 'core/providers.dart';
import 'core/storage/app_database.dart';
import 'core/storage/database_connection.dart';
import 'core/storage/legacy_migration.dart';
import 'core/storage/preferences_service.dart';
import 'core/storage/seed_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/currency.dart';
import 'core/utils/formatters.dart';
import 'features/money/data/recurring_repository.dart';
import 'features/settings/data/auto_backup_service.dart';
import 'features/settings/data/settings_repository.dart';
import 'core/errors/error_log.dart';

/// Initializes storage, seeds first-launch defaults, and runs the app.
///
/// If storage init fails (e.g. web without `sqlite3.wasm`), we render a
/// readable error instead of a blank screen — a silent white void is never
/// an acceptable failure mode.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Older installs kept the database in the Files-visible Documents
    // directory. Move it before opening, or the app would silently
    // start over on an empty file.
    await migrateDatabaseOutOfDocuments();
    await AutoBackupService.migrateOutOfDocuments();
    final database = AppDatabase(openAppDatabaseConnection());
    final preferences = await PreferencesService.create();

    // Money formatting follows the user, not the developer. Currency was
    // a hardcoded '$', so nobody outside the US could read their own
    // figures. Symbol and separators come from the saved preference,
    // defaulting to the device locale on first launch.
    final deviceLocale =
        WidgetsBinding.instance.platformDispatcher.locale.toString();
    Formatters.configureCurrency(
      symbol: preferences.currencySymbol ??
          CurrencyOptions.symbolForLocale(deviceLocale),
      locale: deviceLocale,
    );

    // Seeding and legacy migration are idempotent but not free (~a dozen
    // queries). Run them only when the data revision moved — reset and
    // backup import clear the flag so both re-run on the next launch.
    // Non-fatal: on failure the revision stays unset, so the next launch
    // retries instead of the app refusing to start over starter data.
    if (preferences.dataRevision != AppConstants.dataRevision) {
      try {
        // Seed defaults into empty tables.
        await SeedService(database).seedIfNeeded();
        // Rewrite older data into the current shape.
        await LegacyMigration(database).run();
        await preferences.setDataRevision(AppConstants.dataRevision);
      } catch (e) {
        logError('bootstrap.seed', e);
      }
    }

    // Snapshot this month's income once so surplus history stays honest
    // even if the configured income changes later. Write-free after the
    // first launch of each month.
    //
    // Everything from here down is bookkeeping: useful, never worth
    // refusing to launch over.
    try {
      await SettingsRepository(database).ensureIncomeSnapshot();
    } catch (e) {
      logError('bootstrap.incomeSnapshot', e);
    }

    // Recurring expenses land at launch — not only when the Money tab
    // is opened — including every month missed while the app was closed.
    try {
      await RecurringRepository(database).materialize();
    } catch (e) {
      logError('bootstrap.recurring', e);
    }

    // A Live Activity outlives the process that started it, so a
    // force-quit (or a reset) could leave a lock-screen timer counting
    // forever with nothing in the app able to dismiss it.
    try {
      await LiveActivityService()
          .reconcile(timerRunning: preferences.runningTimer != null);
    } catch (e) {
      logError('bootstrap.liveActivity', e);
    }

    // Re-arm OS notification schedules once a day. Without this, a
    // timezone change, a DST shift, an OS restore, or a revoked-then-
    // restored permission left the app believing in nudges the system
    // had quietly dropped.
    try {
      await NotificationReconciler(
        database: database,
        preferences: preferences,
        notifications: NotificationService(),
      ).reconcile();
    } catch (e) {
      logError('bootstrap.notifications', e);
    }

    // The Swift bridge: mirror the app's nouns for Siri's entity queries
    // and drain any captures Siri wrote while the engine was down. Web
    // has neither a filesystem contract nor Siri.
    //
    // ALL of it is best-effort and non-fatal. It used to run inside the
    // outer try, so one unreadable queue file (or a container the OS
    // wouldn't hand over) fell through to the "Storage didn't start"
    // screen — permanently, since the file was still there next launch,
    // and with an error message that blamed the database. Storage is
    // the only thing worth refusing to launch over.
    BridgePaths? bridge;
    EntityMirrorService? mirror;
    if (!kIsWeb) {
      try {
        bridge = await BridgePaths.resolve();
        mirror = EntityMirrorService(database, bridge);
        await mirror.start();
      } catch (e) {
        logError('bootstrap.bridge', e);
        bridge = null;
        mirror = null;
      }
      if (bridge != null) {
        try {
          final drain = CaptureQueueDrain(database, bridge);
          final result = await drain.drain();
          // Reminders captured by voice need their OS schedule reconciled
          // the moment we can (Swift already armed a provisional one).
          if ((result.remindersChanged ||
                  result.cancelNotificationIds.isNotEmpty) &&
              preferences.notificationsEnabled) {
            final notifications = NotificationService();
            await notifications.cancelMany(result.cancelNotificationIds);
            final reminders = await database.select(database.reminders).get();
            await ReminderScheduler(notifications)
                .syncAll(reminders, appEnabled: true);
          }
        } catch (e) {
          logError('bootstrap.drain', e);
        }
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
    logError('bootstrap.fatal', error);
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

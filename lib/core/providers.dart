import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notifications/notification_service.dart';
import 'notifications/reminder_scheduler.dart';
import 'storage/app_database.dart';
import 'storage/preferences_service.dart';

/// App-level singletons. Database and preferences are created in bootstrap
/// and injected via ProviderScope overrides; tests override them the same way.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Overridden in bootstrap'),
);

final preferencesProvider = Provider<PreferencesService>(
  (ref) => throw UnimplementedError('Overridden in bootstrap'),
);

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(ref.watch(notificationServiceProvider)),
);

/// A ticking "today" so week/month windows roll over without a restart.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

DateTime readNow(Ref ref) =>
    ref.watch(clockProvider).valueOrNull ?? DateTime.now();

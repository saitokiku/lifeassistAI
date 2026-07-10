import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notifications/notification_service.dart';
import 'notifications/reminder_scheduler.dart';
import 'storage/app_database.dart';
import 'storage/preferences_service.dart';
import 'utils/date_utils.dart';

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

/// A ticking clock so time-derived providers roll over without a restart.
/// Nothing should watch this directly — depend on [dayProvider] or
/// [dayPartProvider], which only notify when their coarser value changes.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

/// Today as a date-only value. Recomputed every minute, but equal values
/// don't notify — dependents (and their drift streams) rebuild once per
/// calendar day instead of once per minute.
final dayProvider = Provider<DateTime>((ref) {
  final now = ref.watch(clockProvider).valueOrNull ?? DateTime.now();
  return AppDateUtils.dateOnly(now);
});

/// The date every data window derives from.
DateTime readToday(Ref ref) => ref.watch(dayProvider);

/// Coarse time of day for greeting/emphasis. Notifies at most a few times
/// a day, so hour-aware UI doesn't pay the per-minute rebuild either.
enum DayPart {
  late_,
  morning,
  afternoon,
  evening;

  static DayPart of(DateTime now) {
    final h = now.hour;
    if (h < 5) return DayPart.late_;
    if (h < 12) return DayPart.morning;
    if (h < 17) return DayPart.afternoon;
    return DayPart.evening;
  }
}

final dayPartProvider = Provider<DayPart>((ref) {
  final now = ref.watch(clockProvider).valueOrNull ?? DateTime.now();
  return DayPart.of(now);
});

import '../../../core/storage/app_database.dart';

/// Display-ready reminders state.
class RemindersState {
  const RemindersState({
    required this.reminders,
    required this.appNotificationsEnabled,
    required this.platformSupported,
  });

  final List<Reminder> reminders;

  /// App-level master toggle (persisted in preferences).
  final bool appNotificationsEnabled;

  /// False on web, where local notification scheduling is unavailable.
  final bool platformSupported;

  int get enabledCount => reminders.where((r) => r.enabled).length;
}

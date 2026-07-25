/// App-wide constants. Core user data lives in the database, not here.
class AppConstants {
  AppConstants._();

  static const String appName = 'Life Assist';

  /// Parked ideas cool off for this many days before activation is allowed
  /// (unless they directly help the main goal right now).
  static const int ideaCoolingDays = 7;

  /// Weeks start on Monday everywhere in the app.
  static const int firstDayOfWeek = DateTime.monday;

  /// Envelope version stamped on exports. Tracks the DATABASE schema
  /// version so an export from a newer app is recognisable as such —
  /// it sat at '4' while the schema moved to 7, which meant a v6 export
  /// (carrying notes) and a real v4 export (without) were labelled
  /// identically and the "backup is from a newer version" guard could
  /// never fire. Older backups still import; see BackupService and
  /// LegacyMigration.
  static const String exportSchemaVersion = '7';

  /// Bump when SeedService or LegacyMigration gain new work. Bootstrap
  /// skips both while the stored preference matches; reset and import
  /// clear the preference so the next launch re-runs them.
  static const int dataRevision = 3;

  /// Generation of the OS notification-id layout. Bumping this makes
  /// the next launch cancel every pending notification once and re-arm
  /// from the database, so ids from an older scheme can't linger
  /// beyond cancellation. 1 = block-aligned ids (schema v7).
  static const int notificationIdScheme = 1;
}

/// Short, plain product copy used across the app. One voice: calm, direct,
/// no jargon, never scolding.
class AppCopy {
  AppCopy._();

  // Screen orientation lines
  static const String moneyTagline = 'Where the month stands.';
  static const String timeTagline = 'Your week, in hours.';
  static const String youTagline = 'Principles, systems, and settings.';
  static const String habitsTagline = 'Small daily supports.';
  static const String ideasTagline = 'Catch ideas now, decide later.';
  static const String remindersTagline = 'Gentle nudges through the day.';
  static const String settingsTagline = 'Targets, appearance, and your data.';

  // Shared feedback
  static const String dataSafeRetry = 'Your data is safe. Give it another try.';

  // Concept explanations, used in empty states and helper text
  static const String ideasCoolingExplainer =
      'New ideas wait a week before you act on them. Most lose their shine; '
      'the good ones survive the wait.';
  static const String recoveryExplainer =
      'Downtime is part of the plan, not a failure of it.';
}

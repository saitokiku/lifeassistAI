/// App-wide constants. Core user data lives in the database, not here.
class AppConstants {
  AppConstants._();

  static const String appName = 'Life Assist';

  /// Placeholder bundle id. Change in Xcode / android/app/build.gradle when
  /// wiring real signing. Kept here so docs and code agree on one string.
  static const String bundleIdPlaceholder = 'com.kaizen.lifedashboard';

  /// Parked ideas cool off for this many days before activation is allowed
  /// (unless they directly help the main goal right now).
  static const int ideaCoolingDays = 7;

  /// Weeks start on Monday everywhere in the app.
  static const int firstDayOfWeek = DateTime.monday;

  /// '4' stores money as integer cents and adds the journal. Older
  /// backups are still importable; see BackupService and LegacyMigration.
  static const String exportSchemaVersion = '4';

  /// Bump when SeedService or LegacyMigration gain new work. Bootstrap
  /// skips both while the stored preference matches; reset and import
  /// clear the preference so the next launch re-runs them.
  static const int dataRevision = 3;
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

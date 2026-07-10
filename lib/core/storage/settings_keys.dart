/// Keys for the SettingsEntries key-value table (core, exported data)
/// and for SharedPreferences (small app-only flags).
///
/// Stored key strings never change once shipped — a few predate the
/// universal main-goal redesign and keep their historical names so existing
/// databases and backups stay readable.
class SettingsKeys {
  SettingsKeys._();

  // Database-backed (exported/imported with user data)
  static const displayName = 'displayName';
  static const monthlyNetIncome = 'monthlyNetIncome';
  static const targetSurplusLow = 'targetSurplusLow';
  static const targetSurplusHigh = 'targetSurplusHigh';
  static const birthday = 'birthday'; // yyyy-MM-dd, absent until set
  static const retirementAnnualTarget = 'rothIraAnnualTarget'; // legacy name
  static const retirementContributed = 'rothIraContributed'; // legacy name
  static const brokerageBalance = 'brokerageBalance';
  static const savingsBalance = 'savingsBalance';
  static const philosophyText = 'philosophyText';

  /// Comma-separated module keys the Today screen shows
  /// (see DashboardAreas). Absent = all modules.
  static const dashboardAreas = 'dashboardAreas';

  // SharedPreferences-backed (device-local app flags)
  static const prefOnboardingComplete = 'onboardingComplete';
  static const prefThemeMode = 'themeMode'; // system | dark | light
  static const prefNotificationsEnabled = 'notificationsEnabled';
}

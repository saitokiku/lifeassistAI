/// Keys for the SettingsEntries key-value table (core, exported data)
/// and for SharedPreferences (small app-only flags).
class SettingsKeys {
  SettingsKeys._();

  // Database-backed (exported/imported with user data)
  static const monthlyNetIncome = 'monthlyNetIncome';
  static const targetSurplusLow = 'targetSurplusLow';
  static const targetSurplusHigh = 'targetSurplusHigh';
  static const birthday = 'birthday'; // yyyy-MM-dd, absent until set
  static const rothIraAnnualTarget = 'rothIraAnnualTarget';
  static const rothIraContributed = 'rothIraContributed';
  static const brokerageBalance = 'brokerageBalance';
  static const savingsBalance = 'savingsBalance';
  static const philosophyText = 'philosophyText';

  // SharedPreferences-backed (device-local app flags)
  static const prefOnboardingComplete = 'onboardingComplete';
  static const prefThemeMode = 'themeMode'; // system | dark | light
  static const prefNotificationsEnabled = 'notificationsEnabled';
}

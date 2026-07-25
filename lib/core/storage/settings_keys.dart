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

  /// ISO timestamp of the most recent successful export (manual or auto).
  static const lastBackupAt = 'lastBackupAt';

  /// Net income snapshots per month: `<prefix>2026-07` → value. The
  /// surplus history reads the nearest snapshot at or before each month.
  static const incomeForMonthPrefix = 'incomeFor.';

  // SharedPreferences-backed (device-local app flags)
  static const prefOnboardingComplete = 'onboardingComplete';
  static const prefThemeMode = 'themeMode'; // system | dark | light
  static const prefNotificationsEnabled = 'notificationsEnabled';

  /// Bumps when seeds/legacy migration change; bootstrap skips both while
  /// the stored value matches (a reset or import clears it).
  static const prefDataRevision = 'dataRevision';

  /// Biometric/PIN gate on app open (device-local by design).
  static const prefAppLockEnabled = 'appLockEnabled';

  /// ISO timestamp of the last automatic rolling backup.
  static const prefLastAutoBackupAt = 'lastAutoBackupAt';

  /// A live time-block timer survives restarts via these two.
  static const prefTimerBudgetId = 'timerBudgetId';
  static const prefTimerStartedAt = 'timerStartedAt';

  /// One-time "what's here" card on Today (Notes, Health auto-habits,
  /// widgets). Set once dismissed; never shown again.
  static const prefLaunchDiscoveryDismissed = 'launchDiscoveryDismissed';

  /// Live Obsidian vault: notes mirror to Documents/LifeAssistVault as
  /// they change, and outside edits fold back in on resume. Default on.
  static const prefLiveVaultEnabled = 'liveVaultEnabled';

  /// Notification-id scheme generation. Schema v7 renumbered every
  /// reminder and habit onto block-aligned ids (NotificationIds), which
  /// orphans anything armed under the old hashed ids — bootstrap does
  /// one `cancelAll()` and a full re-arm when this doesn't match
  /// [AppConstants.notificationIdScheme].
  static const prefNotificationIdScheme = 'notificationIdScheme';

  /// Currency symbol shown with every amount (`$`, `€`, `£`, `¥`…).
  /// Absent = derive from the device locale on first launch. Purely a
  /// display setting: amounts are stored as integer cents and are never
  /// converted between currencies.
  static const prefCurrencySymbol = 'currencySymbol';

  /// Date key (`yyyy-MM-dd`) of the last successful reminder re-arm.
  /// Schedules are reconciled once per day at launch so a timezone
  /// change, a DST shift, or an OS-level revoke can't leave the app
  /// believing in nudges the system has dropped.
  static const prefRemindersArmedOn = 'remindersArmedOn';
}

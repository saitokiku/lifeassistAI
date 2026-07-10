/// Seed defaults. These are inserted into the local database on first launch
/// and become fully user-editable records after that. They are never read
/// directly by UI once seeded.
///
/// Defaults are deliberately neutral: real numbers come from the user during
/// onboarding or later, and screens are designed to guide setup when a value
/// is still unset.
class DefaultTargets {
  DefaultTargets._();

  // Money. Zero means "not set yet" — the Money screen invites setup
  // instead of pretending to know the user's finances.
  static const double monthlyNetIncome = 0;
  static const double targetSurplusLow = 0;
  static const double targetSurplusHigh = 0;
  static const double retirementAnnualTarget = 0;

  // Time
  static const double weeklyGoalHoursTarget = 10;
  static const double weeklyRecoveryFloorHours = 8;
  static const double recoveryWarningThresholdHours = 5;

  /// name, monthly target, flag rule key (see BudgetFlagType).
  /// Targets start at 0 with no flag rule; the category editor is where
  /// each lane gets a real target and a leak rule.
  static const List<(String, double, String)> budgetCategories = [
    ('Housing', 0, 'none'),
    ('Groceries', 0, 'none'),
    ('Transport', 0, 'none'),
    ('Eating out', 0, 'none'),
    ('Subscriptions', 0, 'none'),
    ('Health', 0, 'none'),
    ('Fun', 0, 'none'),
    ('Travel', 0, 'none'),
  ];

  /// name, kind key, weekly target hours.
  static const List<(String, String, double)> weeklyTimeBudgets = [
    ('Sleep', 'sleep', 56),
    ('Work', 'job', 40),
    ('Main goal', 'goal', 10),
    ('Exercise', 'exercise', 4),
    ('Downtime', 'decompress', 8),
    ('Chores & admin', 'admin', 6),
  ];

  /// name, habit type key, unit.
  static const List<(String, String, String?)> habits = [
    ('Exercise', 'duration', 'min'),
    ('Read', 'duration', 'min'),
    ('In bed on time', 'boolean', null),
  ];

  /// title, reminder type key, hour, minute.
  static const List<(String, String, int, int)> reminders = [
    ('Morning plan', 'morningCommand', 8, 0),
    ('Daily step', 'dailyAction', 12, 0),
    ('Evening review', 'nightReview', 21, 30),
  ];
}

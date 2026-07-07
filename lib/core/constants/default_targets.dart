/// Seed defaults. These are inserted into the local database on first launch
/// and become fully user-editable records after that. They are never read
/// directly by UI once seeded.
class DefaultTargets {
  DefaultTargets._();

  // Money
  static const double monthlyNetIncome = 6942;
  static const double targetSurplusLow = 3200;
  static const double targetSurplusHigh = 3800;
  static const double rothIraAnnualTarget = 7000;

  // Time
  static const double weeklyKaizenHoursTarget = 42;
  static const double weeklyRecoveryFloorHours = 10.5;
  static const double recoveryWarningThresholdHours = 5;

  // Kaizen hour status thresholds
  static const double kaizenAlignedHours = 35;
  static const double kaizenWatchHours = 25;

  /// name, monthly target, flag rule key (see BudgetFlagType).
  static const List<(String, double, String)> budgetCategories = [
    ('Housing', 1700, 'warnOverTarget'),
    ('Food', 400, 'warnOverTarget'),
    ('Car', 340, 'warnOverTarget'),
    ('Amazon', 258, 'warnOverTarget'),
    ('Misc', 300, 'warnOverTarget'),
    ('Subscriptions', 60, 'warnOverTarget'),
    ('Fitness', 60, 'warnOverTarget'),
    ('Charity', 125, 'warnOverTarget'),
    ('Poker', 0, 'criticalOverZero'),
    ('Weed', 0, 'criticalOverZero'),
    ('Restaurants/desserts', 0, 'warnOverZeroUnlessIntentional'),
    ('Travel', 0, 'warnOverZero'),
  ];

  /// name, kind key, weekly target hours.
  static const List<(String, String, double)> weeklyTimeBudgets = [
    ('Sleep', 'sleep', 52.5),
    ('Job', 'job', 30),
    ('Kaizen', 'kaizen', 42),
    ('Admin', 'admin', 14),
    ('Decompress', 'decompress', 10.5),
    ('Meals', 'meals', 7),
    ('Exercise', 'exercise', 5),
    ('Volunteering', 'volunteering', 3),
    ('Toastmasters', 'toastmasters', 2),
    ('Meditation', 'meditation', 1.5),
  ];

  /// name, habit type key, unit.
  static const List<(String, String, String?)> habits = [
    ('Weed-free', 'boolean', null),
    ('Meditation', 'duration', 'min'),
    ('Exercise', 'duration', 'min'),
    ('Sleep logged', 'numeric', 'hrs'),
    ('Volunteering/service', 'boolean', null),
    ('Toastmasters', 'boolean', null),
  ];

  /// title, reminder type key, hour, minute.
  static const List<(String, String, int, int)> reminders = [
    ('Morning command', 'morningCommand', 8, 0),
    ('Kaizen experiment', 'kaizenExperiment', 12, 0),
    ('Money check', 'moneyCheck', 18, 0),
    ('Night review', 'nightReview', 22, 0),
  ];

  /// Default identity statements: the current operating identity.
  static const List<String> identityStatements = [
    'Builder/operator.',
    'Kaizen growth is the main hunt.',
    'W-2 job is the funding base.',
    'Flipping is winding down.',
    'Freedom is the actual goal.',
  ];

  static const String defaultGrowthMetricName = 'Weekly active learners';
  static const String defaultGrowthMetricUnit = 'users';
  static const double defaultGrowthMetricWeeklyTarget = 10;

  static const String defaultFreedomTargetTitle = 'Freedom number';
  static const String defaultFreedomTargetDescription =
      'Enough passive income and liquidity that work is optional.';
  static const double defaultTargetMonthlyPassiveIncome = 8000;
  static const double defaultTargetLiquidNetWorth = 500000;
}

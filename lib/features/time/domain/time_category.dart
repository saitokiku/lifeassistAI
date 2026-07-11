/// Semantic kinds for time budget categories. The kind drives scoring
/// (main-goal hours, recovery floor, exercise/meditation health points)
/// while names and targets stay fully user-editable.
enum TimeCategoryKind {
  sleep,
  job,
  goal,
  admin,
  decompress,
  meals,
  exercise,
  volunteering,
  meditation,
  other;

  static TimeCategoryKind parse(String raw) => switch (raw) {
        // Pre-v2 stored values; LegacyMigration rewrites them, this is a net.
        'kaizen' => TimeCategoryKind.goal,
        'toastmasters' => TimeCategoryKind.other,
        _ => TimeCategoryKind.values.firstWhere((k) => k.name == raw,
            orElse: () => TimeCategoryKind.other),
      };

  String get label => switch (this) {
        TimeCategoryKind.sleep => 'Sleep',
        TimeCategoryKind.job => 'Work',
        TimeCategoryKind.goal => 'Main goal',
        TimeCategoryKind.admin => 'Chores & admin',
        TimeCategoryKind.decompress => 'Downtime',
        TimeCategoryKind.meals => 'Meals',
        TimeCategoryKind.exercise => 'Exercise',
        TimeCategoryKind.volunteering => 'Volunteering',
        TimeCategoryKind.meditation => 'Meditation',
        TimeCategoryKind.other => 'Other',
      };

  /// Recovery floor counts downtime hours.
  bool get countsAsRecovery => this == TimeCategoryKind.decompress;

  /// Health points count exercise or meditation.
  bool get countsAsHealth =>
      this == TimeCategoryKind.exercise || this == TimeCategoryKind.meditation;
}

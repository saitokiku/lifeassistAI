/// Semantic kinds for time budget categories. The kind drives scoring
/// (kaizen hours, recovery floor, exercise/meditation health points) while
/// names and targets stay fully user-editable.
enum TimeCategoryKind {
  sleep,
  job,
  kaizen,
  admin,
  decompress,
  meals,
  exercise,
  volunteering,
  toastmasters,
  meditation,
  other;

  static TimeCategoryKind parse(String raw) => TimeCategoryKind.values
      .firstWhere((k) => k.name == raw, orElse: () => TimeCategoryKind.other);

  String get label => switch (this) {
        TimeCategoryKind.sleep => 'Sleep',
        TimeCategoryKind.job => 'Job',
        TimeCategoryKind.kaizen => 'Kaizen',
        TimeCategoryKind.admin => 'Admin',
        TimeCategoryKind.decompress => 'Decompress',
        TimeCategoryKind.meals => 'Meals',
        TimeCategoryKind.exercise => 'Exercise',
        TimeCategoryKind.volunteering => 'Volunteering',
        TimeCategoryKind.toastmasters => 'Toastmasters',
        TimeCategoryKind.meditation => 'Meditation',
        TimeCategoryKind.other => 'Other',
      };

  /// Recovery floor counts decompress hours.
  bool get countsAsRecovery => this == TimeCategoryKind.decompress;

  /// Health points count exercise or meditation.
  bool get countsAsHealth =>
      this == TimeCategoryKind.exercise || this == TimeCategoryKind.meditation;
}

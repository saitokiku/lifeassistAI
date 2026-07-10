/// Reminder categories, each with its own message templates.
///
/// `dailyAction` was stored as `kaizenExperiment` before the universal
/// main-goal redesign; LegacyMigration rewrites old rows, and [parse] maps
/// the old string defensively in case one slips through.
enum ReminderType {
  morningCommand,
  dailyAction,
  moneyCheck,
  nightReview,
  custom;

  static ReminderType parse(String raw) {
    if (raw == 'kaizenExperiment') return ReminderType.dailyAction;
    return ReminderType.values
        .firstWhere((t) => t.name == raw, orElse: () => ReminderType.custom);
  }

  String get label => switch (this) {
        ReminderType.morningCommand => 'Morning plan',
        ReminderType.dailyAction => 'Daily step',
        ReminderType.moneyCheck => 'Money check',
        ReminderType.nightReview => 'Evening review',
        ReminderType.custom => 'Custom',
      };
}

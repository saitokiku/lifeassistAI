/// Reminder categories, each with its own message templates.
enum ReminderType {
  morningCommand,
  kaizenExperiment,
  moneyCheck,
  nightReview,
  custom;

  static ReminderType parse(String raw) => ReminderType.values
      .firstWhere((t) => t.name == raw, orElse: () => ReminderType.custom);

  String get label => switch (this) {
        ReminderType.morningCommand => 'Morning command',
        ReminderType.kaizenExperiment => 'Kaizen experiment',
        ReminderType.moneyCheck => 'Money check',
        ReminderType.nightReview => 'Night review',
        ReminderType.custom => 'Custom',
      };
}

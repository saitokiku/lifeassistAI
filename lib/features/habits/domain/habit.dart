/// Habit domain model and type enum.
library;

export '../../../core/storage/app_database.dart' show Habit;

enum HabitType {
  boolean,
  numeric,
  duration;

  static HabitType parse(String raw) => HabitType.values
      .firstWhere((t) => t.name == raw, orElse: () => HabitType.boolean);

  String get label => switch (this) {
        HabitType.boolean => 'Done / not done',
        HabitType.numeric => 'Numeric value',
        HabitType.duration => 'Duration (minutes)',
      };
}

/// Message templates per reminder type. Reminders are stored in the database
/// and editable; these are only used to build defaults and rotating bodies.
class ReminderTemplates {
  ReminderTemplates._();

  static const Map<String, List<String>> byType = {
    'morningCommand': [
      "Run today's Kaizen experiment before research.",
      'Point the engine at one hunt.',
      'Growth hunt first. Build hunt is fenced.',
    ],
    'kaizenExperiment': [
      'One test. One verdict. Log it.',
      'No verdict yet today? One test before research.',
    ],
    'moneyCheck': [
      'Money is the scoreboard, not the mission.',
      'Undefined misc is fog. Categorize it.',
      'Surplus must move toward freedom.',
    ],
    'nightReview': [
      'Recovery floor is load-bearing. Do not zero it out.',
      'Curiosity is fuel. Point it at one hunt.',
      'Freedom is the goal.',
    ],
    'custom': [
      'Freedom is the goal.',
    ],
  };

  static String defaultMessageFor(String type) {
    final list = byType[type] ?? byType['custom']!;
    return list.first;
  }

  /// Deterministic rotation so the same day always shows the same line.
  static String rotatingMessageFor(String type, DateTime day) {
    final list = byType[type] ?? byType['custom']!;
    return list[day.difference(DateTime(2026)).inDays.abs() % list.length];
  }
}

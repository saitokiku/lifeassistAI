/// Message templates per reminder type. Reminders are stored in the database
/// and editable; these are only used to build defaults and rotating bodies.
class ReminderTemplates {
  ReminderTemplates._();

  static const Map<String, List<String>> byType = {
    'morningCommand': [
      'What would make today count? Pick it now.',
      'One clear priority beats a long list.',
      'Look at today before today happens to you.',
    ],
    'dailyAction': [
      'One small step toward your goal. Log what happened.',
      'No step yet today? Small counts — take one now.',
    ],
    'moneyCheck': [
      'A quick look at spending keeps the month honest.',
      'Thirty seconds: log anything you spent today.',
      'Uncategorized spending hides patterns. Give it a lane.',
    ],
    'nightReview': [
      'Close the day: what moved, what stalled?',
      'Two minutes of review saves tomorrow an hour.',
      'Check off what you did. Let the rest wait for morning.',
    ],
    'custom': [
      'This is your reminder.',
    ],
  };

  /// Legacy type key from before the universal main-goal redesign.
  static const String legacyDailyActionType = 'kaizenExperiment';

  static String defaultMessageFor(String type) {
    final list = byType[_normalize(type)] ?? byType['custom']!;
    return list.first;
  }

  /// Deterministic rotation so the same day always shows the same line.
  static String rotatingMessageFor(String type, DateTime day) {
    final list = byType[_normalize(type)] ?? byType['custom']!;
    return list[day.difference(DateTime(2026)).inDays.abs() % list.length];
  }

  static String _normalize(String type) =>
      type == legacyDailyActionType ? 'dailyAction' : type;
}

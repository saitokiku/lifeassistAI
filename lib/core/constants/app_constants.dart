/// App-wide constants. Core user data lives in the database, not here.
class AppConstants {
  AppConstants._();

  static const String appName = 'Life Dashboard';

  /// Placeholder bundle id. Change in Xcode / android/app/build.gradle when
  /// wiring real signing. Kept here so docs and code agree on one string.
  static const String bundleIdPlaceholder = 'com.kaizen.lifedashboard';

  static const String philosophyLine =
      'Money = scoreboard · Curiosity = engine · Freedom = goal';

  /// Parked ideas cool off for this many days before activation is allowed
  /// (unless they directly help Kaizen this week).
  static const int ideaCoolingDays = 7;

  /// Age the user wants to hit their lock-in deadline by.
  static const int lockInAge = 28;

  /// Weeks start on Monday everywhere in the app.
  static const int firstDayOfWeek = DateTime.monday;

  static const String exportSchemaVersion = '1';
}

/// Short, direct operator copy used across the app.
class AppCopy {
  AppCopy._();

  static const String moneyScoreboard = 'Money is the scoreboard, not the mission.';
  static const String curiosityCaptured = 'Curiosity captured. Not chased.';
  static const String recoveryLoadBearing = 'Recovery floor is load-bearing.';
  static const String oneHunt = 'Point the engine at one hunt.';
  static const String freedomGoal = 'Freedom is the goal.';
  static const String buildFenced = 'Build mode is fenced. Growth mode first.';
  static const String oneTestOneVerdict = 'One test. One verdict.';
  static const String growthHuntFirst = 'Growth hunt first.';
  static const String buildHuntFenced = 'Build hunt is fenced.';
  static const String noVerdictYet = 'No verdict yet. One test before research.';
  static const String miscFog = 'Undefined misc is fog. Categorize it.';
  static const String surplusFreedom = 'Surplus must move toward freedom.';
  static const String availableTimeBudget = 'Available time is the real budget.';
  static const String kaizenPriorityBlock = 'Kaizen is the priority block.';
  static const String recoveryNotZero = 'Recovery floor cannot hit zero.';
  static const String habitsSupport = 'Habits support the mission. They are not the mission.';
  static const String engineOneHunt = 'The engine is good. Point it at one hunt.';
  static const String experimentBeforeResearch = "Run today's Kaizen experiment before research.";
}

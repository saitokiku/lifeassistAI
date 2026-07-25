import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/weekdays.dart';
import '../data/habits_repository.dart';
import '../domain/habit_log.dart';

/// One habit with its derived streak/weekly numbers.
class HabitView {
  // Not const: the derived values below are cached in late finals, so
  // each view computes its streak once instead of on every rebuild.
  HabitView({
    required this.habit,
    required this.logs,
    required this.today,
  });

  final Habit habit;
  final List<HabitLog> logs; // newest first, this habit only
  final DateTime today;

  /// Cached: this was an uncached getter allocating a fresh Set on every
  /// access, and `streak` / `weeklyCount` each call it — so every
  /// rebuild of a habit card re-allocated and re-walked.
  late final Set<String> loggedDays = logs.map((l) => l.date).toSet();

  HabitLog? get todayLog {
    final key = AppDateUtils.dateKey(today);
    for (final l in logs) {
      if (l.date == key) return l;
    }
    return null;
  }

  bool get doneToday => todayLog != null;

  /// Whether the habit's schedule includes today. Off-schedule days don't
  /// nag and don't break streaks.
  bool get dueToday => WeekdayMask.isDueOn(habit.weekdays, today);

  /// True when the habit runs on a subset of the week.
  bool get isScheduled => habit.weekdays & WeekdayMask.all != WeekdayMask.all;

  late final int streak =
      HabitStats.streak(loggedDays, today, weekdays: habit.weekdays);

  /// True when the streak reached the edge of the log window, so the
  /// real run is at least this long but can't be counted exactly.
  /// Display as "N+" — the alternative was a number that silently
  /// stopped growing at the window size and read as a broken streak.
  bool get streakIsCapped => streak >= HabitsRepository.logWindowDays;

  late final int weeklyCount = HabitStats.weeklyCount(loggedDays, today);

  /// Scheduled days per week, for honest x/y progress.
  int get scheduledPerWeek =>
      HabitStats.scheduledCountThisWeek(habit.weekdays);

  bool get hasReminder =>
      habit.reminderHour != null && habit.reminderMinute != null;
}

class HabitsState {
  const HabitsState({required this.habits, required this.today});

  final List<HabitView> habits;
  final DateTime today;

  /// Health metrics whose presence on a habit marks it as a movement or
  /// mindfulness habit, whatever the user named it.
  static const _healthMetrics = {
    'steps',
    'workoutMinutes',
    'mindfulMinutes',
  };

  /// True when a movement/mindfulness habit is logged today — used by the
  /// day score's health points alongside time blocks.
  ///
  /// Identified by the habit's Apple Health mapping, not by its name. The
  /// old test was `name.contains('exercise') || name.contains('meditat')`,
  /// so habits called "Gym", "Yoga", or "Run" could never earn the
  /// points, and no non-English user could earn them at all. Names are
  /// still honoured as a fallback for unmapped habits, in both spellings
  /// people actually use.
  bool get exerciseOrMeditationToday =>
      habits.any((h) => h.doneToday && _countsAsHealth(h.habit));

  static bool _countsAsHealth(Habit habit) {
    final metric = habit.healthMetric;
    if (metric != null && _healthMetrics.contains(metric)) return true;
    final name = habit.name.toLowerCase();
    return _healthNameHints.any(name.contains);
  }

  /// Fallback only — a habit with a Health mapping never reaches this.
  static const _healthNameHints = [
    'exercise', 'workout', 'gym', 'run', 'walk', 'yoga', 'swim', 'cycl',
    'lift', 'stretch', 'meditat', 'mindful', 'breath',
  ];
}

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/habit_log.dart';

/// One habit with its derived streak/weekly numbers.
class HabitView {
  const HabitView({
    required this.habit,
    required this.logs,
    required this.today,
  });

  final Habit habit;
  final List<HabitLog> logs; // newest first, this habit only
  final DateTime today;

  Set<String> get loggedDays => logs.map((l) => l.date).toSet();

  HabitLog? get todayLog {
    final key = AppDateUtils.dateKey(today);
    for (final l in logs) {
      if (l.date == key) return l;
    }
    return null;
  }

  bool get doneToday => todayLog != null;

  int get streak => HabitStats.streak(loggedDays, today);

  int get weeklyCount => HabitStats.weeklyCount(loggedDays, today);
}

class HabitsState {
  const HabitsState({required this.habits, required this.today});

  final List<HabitView> habits;
  final DateTime today;

  /// True when any exercise/meditation-named habit is logged today. Used by
  /// the Focus Integrity health points alongside time blocks.
  bool get exerciseOrMeditationToday => habits.any((h) {
        final name = h.habit.name.toLowerCase();
        return (name.contains('exercise') || name.contains('meditat')) &&
            h.doneToday;
      });
}

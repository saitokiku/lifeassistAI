import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../focus/application/focus_controller.dart';
import '../../habits/application/habits_controller.dart';
import '../../ideas/application/ideas_controller.dart';
import '../../money/application/money_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../time/application/time_controller.dart';
import 'dashboard_state.dart';

/// Aggregates the module states into one dashboard state.
/// Null while any underlying stream is still loading.
final dashboardStateProvider = Provider<DashboardState?>((ref) {
  final focus = ref.watch(focusStateProvider);
  final money = ref.watch(moneyStateProvider);
  final time = ref.watch(timeStateProvider);
  final settings = ref.watch(settingsProvider).valueOrNull;
  final habits = ref.watch(habitsStateProvider);
  final ideas = ref.watch(ideasStateProvider);

  if (focus == null ||
      money == null ||
      time == null ||
      settings == null ||
      habits == null ||
      ideas == null) {
    return null;
  }

  // Health points come from either a logged habit or a logged time block.
  final exerciseOrMeditationToday =
      habits.exerciseOrMeditationToday || time.healthHoursToday > 0;

  return DashboardState(
    focus: focus,
    money: money,
    time: time,
    settings: settings,
    exerciseOrMeditationToday: exerciseOrMeditationToday,
    parkedIdeaCount: ideas.parkedCount,
    ideasDueForReview: ideas.dueForReview.length,
  );
});

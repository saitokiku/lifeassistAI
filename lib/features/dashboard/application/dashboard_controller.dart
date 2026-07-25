import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../focus/application/focus_controller.dart';
import '../../habits/application/habits_controller.dart';
import '../../ideas/application/ideas_controller.dart';
import '../../money/application/money_controller.dart';
import '../../review/application/review_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../time/application/time_controller.dart';
import 'dashboard_state.dart';

/// Aggregates the module states into one dashboard state.
/// Null while any underlying stream is still loading.
/// True when a stream feeding Today has errored.
///
/// Today aggregates six sources and signalled loading with `null`, so an
/// errored stream (`isLoading == false`, `valueOrNull == null`) was
/// indistinguishable from "no data yet" — and the downstream states
/// substitute empty lists, so the screen rendered a complete-looking day
/// of zeros with a score. Every other screen has a `hasError` branch;
/// the one that aggregates everything is the one that needs it most.
final dashboardHasErrorProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).hasError ||
      ref.watch(currentWeekReviewProvider).hasError ||
      ref.watch(dailyActionsProvider).hasError ||
      ref.watch(budgetCategoriesProvider).hasError ||
      ref.watch(timeBudgetsProvider).hasError ||
      ref.watch(habitsProvider).hasError;
});

/// Re-subscribes every source Today depends on — the retry action for
/// [dashboardHasErrorProvider].
void refreshDashboard(WidgetRef ref) {
  ref.invalidate(settingsProvider);
  ref.invalidate(currentWeekReviewProvider);
  ref.invalidate(dailyActionsProvider);
  ref.invalidate(budgetCategoriesProvider);
  ref.invalidate(timeBudgetsProvider);
  ref.invalidate(habitsProvider);
}

final dashboardStateProvider = Provider<DashboardState?>((ref) {
  final focus = ref.watch(focusStateProvider);
  final money = ref.watch(moneyStateProvider);
  final time = ref.watch(timeStateProvider);
  final settings = ref.watch(settingsProvider).valueOrNull;
  final habits = ref.watch(habitsStateProvider);
  final ideas = ref.watch(ideasStateProvider);
  final dayPart = ref.watch(dayPartProvider);
  final weeklyReview = ref.watch(currentWeekReviewProvider).valueOrNull;

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
    dayPart: dayPart,
    weeklyReviewDone: weeklyReview != null,
  );
});

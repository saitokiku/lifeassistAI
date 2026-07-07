import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../habits/application/habits_controller.dart';
import '../../identity/application/identity_controller.dart';
import '../../ideas/application/ideas_controller.dart';
import '../../kaizen/application/kaizen_controller.dart';
import '../../money/application/money_controller.dart';
import '../../time/application/time_controller.dart';
import 'dashboard_state.dart';

/// Aggregates the module states into one dashboard state.
/// Null while any underlying stream is still loading.
final dashboardStateProvider = Provider<DashboardState?>((ref) {
  final kaizen = ref.watch(kaizenStateProvider);
  final money = ref.watch(moneyStateProvider);
  final time = ref.watch(timeStateProvider);
  final identity = ref.watch(identityStateProvider);
  final habits = ref.watch(habitsStateProvider);
  final ideas = ref.watch(ideasStateProvider);

  if (kaizen == null ||
      money == null ||
      time == null ||
      identity == null ||
      habits == null ||
      ideas == null) {
    return null;
  }

  // Health points come from either a logged habit or a logged time block.
  final exerciseOrMeditationToday =
      habits.exerciseOrMeditationToday || time.healthHoursToday > 0;

  return DashboardState(
    kaizen: kaizen,
    money: money,
    time: time,
    identity: identity,
    exerciseOrMeditationToday: exerciseOrMeditationToday,
    parkedIdeaCount: ideas.parkedCount,
    ideasDueForReview: ideas.dueForReview.length,
  );
});

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../application/habits_state.dart';

/// Summary card: habits done today and best streaks.
class HabitStreakCard extends StatelessWidget {
  const HabitStreakCard({super.key, required this.state});

  final HabitsState state;

  @override
  Widget build(BuildContext context) {
    final doneToday = state.habits.where((h) => h.doneToday).length;
    final total = state.habits.length;
    final bestStreak = state.habits.isEmpty
        ? 0
        : state.habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

    return MetricCard(
      title: 'Today',
      badgeLabel: doneToday == total && total > 0 ? 'Complete' : '$doneToday/$total',
      badgeLevel: doneToday == total && total > 0
          ? StatusLevel.aligned
          : StatusLevel.neutral,
      bigValue: '$doneToday of $total',
      supportText: 'Best streak ${bestStreak}d · ${AppCopy.habitsSupport}',
    );
  }
}

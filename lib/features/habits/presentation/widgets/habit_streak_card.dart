import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/progress_ring.dart';
import '../../application/habits_state.dart';

/// Summary card: today's completion ring and the best running streak.
class HabitStreakCard extends StatelessWidget {
  const HabitStreakCard({super.key, required this.state});

  final HabitsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = state.habits.where((h) => h.doneToday).length;
    final total = state.habits.length;
    final complete = total > 0 && done == total;
    final bestStreak = state.habits.isEmpty
        ? 0
        : state.habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

    return AppCard(
      child: Row(
        children: [
          ProgressRing(
            progress: total == 0 ? 0 : done / total,
            color: complete ? AppColors.aligned : AppColors.primary,
            size: 48,
            strokeWidth: 5,
            center: complete
                ? const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: AppColors.aligned,
                  )
                : Text(
                    '$done',
                    style: theme.textTheme.numberMedium.copyWith(fontSize: 15),
                  ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done of $total today',
                  style: theme.textTheme.numberMedium,
                ),
                const SizedBox(height: AppSpace.xs),
                if (bestStreak > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: AppColors.watch,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        'Best streak $bestStreak day${bestStreak == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'No streaks running yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/time_state.dart';

/// Hero: the unlogged remainder of today, with logged-vs-free at a glance.
class AvailableTimeCard extends StatelessWidget {
  const AvailableTimeCard({super.key, required this.state});

  final TimeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logged = state.hoursLoggedToday;

    return AppCard(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE TODAY',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            Formatters.hours(state.availableHoursToday),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 2),
          Text(
            'of 24h unlogged today',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          LabeledProgressBar(
            progress: logged / 24,
            color: AppColors.primary,
            height: 6,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '${Formatters.hours(logged)} logged · '
            '${Formatters.hours(state.remainingWeekHours)} of weekly targets open',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

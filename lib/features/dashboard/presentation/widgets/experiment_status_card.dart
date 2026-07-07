import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../kaizen/domain/daily_experiment.dart';
import '../../application/dashboard_state.dart';

/// Whether today's kill-or-confirm experiment has a verdict.
class ExperimentStatusCard extends StatelessWidget {
  const ExperimentStatusCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final experiment = state.kaizen.todayExperiment;
    final streak = state.kaizen.experimentStreak;

    if (experiment == null) {
      return MetricCard(
        title: 'Daily Experiment',
        badgeLabel: 'No verdict',
        badgeLevel: StatusLevel.watch,
        supportText: AppCopy.noVerdictYet,
        onTap: () => context.go('/kaizen'),
        child: Row(
          children: [
            FilledButton(
              onPressed: () => context.go('/kaizen'),
              child: const Text('Log experiment'),
            ),
            const Spacer(),
            _streakChip(context, streak),
          ],
        ),
      );
    }

    final verdict = experiment.verdictEnum;
    return MetricCard(
      title: 'Daily Experiment',
      badgeLabel: verdict.label,
      badgeLevel: switch (verdict) {
        ExperimentVerdict.confirm => StatusLevel.aligned,
        ExperimentVerdict.iterate => StatusLevel.watch,
        ExperimentVerdict.kill => StatusLevel.critical,
      },
      supportText: experiment.hypothesis,
      onTap: () => context.go('/kaizen'),
      child: Row(
        children: [
          Text(AppCopy.oneTestOneVerdict,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const Spacer(),
          _streakChip(context, streak),
        ],
      ),
    );
  }

  Widget _streakChip(BuildContext context, int streak) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department,
            size: 16,
            color:
                streak > 0 ? AppColors.watch : theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text('$streak-day streak', style: theme.textTheme.bodySmall),
      ],
    );
  }
}

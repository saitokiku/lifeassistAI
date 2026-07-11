import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../focus/domain/main_goal.dart';
import '../../../focus/domain/milestone.dart';
import '../../../focus/presentation/widgets/growth_metric_chart.dart';
import '../../application/dashboard_state.dart';

/// The main goal at a glance: next milestone, streak, and the tracked
/// measure's 7-day trend. Tapping opens the Focus tab.
class GoalSnapshotCard extends StatelessWidget {
  const GoalSnapshotCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = state.goal;
    if (goal == null) return const SizedBox.shrink();

    final focus = state.focus;
    final milestone = focus.nextMilestone;
    final metric = focus.activeMetric;
    final streak = focus.actionStreak;

    return AppCard(
      onTap: () => context.go('/focus'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.textTertiary,
                  ),
                ),
              ),
              if (goal.isPaused)
                const StatusBadge(label: 'Paused', level: StatusLevel.neutral)
              else if (focus.todayActionLogged)
                const StatusBadge(
                    label: 'Step logged', level: StatusLevel.aligned)
              else
                const StatusBadge(
                    label: 'No step yet', level: StatusLevel.watch),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          if (milestone != null) ...[
            Text(
              'Next: ${milestone.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            if (milestone.isMeasurable) ...[
              const SizedBox(height: 2),
              Text(
                '${Formatters.number(milestone.currentValue)} of '
                '${Formatters.number(milestone.targetValue)}'
                '${milestone.metricName == null ? '' : ' ${milestone.metricName}'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ] else
            Text(
              focus.milestones.isEmpty
                  ? 'Add a first milestone to give the goal a direction.'
                  : 'All milestones done — set the next one.',
              style: theme.textTheme.titleMedium,
            ),
          if (metric != null) ...[
            const SizedBox(height: AppSpace.md),
            SizedBox(
              height: 40,
              child: Sparkline(
                values: focus.sevenDayTrend,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              '${metric.name} · latest '
              '${Formatters.number(metric.currentValue)} ${metric.unit}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (streak > 0) ...[
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 15,
                  color: AppColors.watch,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  '$streak-day streak',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

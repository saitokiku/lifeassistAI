import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../kaizen/presentation/widgets/growth_metric_chart.dart';
import '../../../kaizen/presentation/widgets/growth_metric_entry_form.dart';
import '../../application/dashboard_state.dart';

/// The one active growth metric: today's value, 7-day trend, inline log.
class GrowthMetricOverviewCard extends StatelessWidget {
  const GrowthMetricOverviewCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metric = state.kaizen.activeMetric;

    if (metric == null) {
      return MetricCard(
        title: 'Growth metric',
        supportText: 'No active hunt yet. Pick the one number that proves '
            'the engine is working.',
        onTap: () => context.go('/kaizen'),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(
            onPressed: () => context.go('/kaizen'),
            child: const Text('Set the metric'),
          ),
        ),
      );
    }

    final todayValue = state.kaizen.todayMetricValue;
    final logged = todayValue != null;

    return AppCard(
      onTap: () => context.go('/kaizen'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.textTertiary,
                  ),
                ),
              ),
              StatusBadge(
                label: logged ? 'Live' : 'Log today',
                level: logged ? StatusLevel.aligned : StatusLevel.watch,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                logged
                    ? '${Formatters.number(todayValue)} ${metric.unit}'
                    : '—',
                style: theme.textTheme.headlineMedium,
              ),
              const Spacer(),
              if (!logged)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                    ),
                  ),
                  onPressed: () =>
                      GrowthMetricEntryForm.show(context, metric: metric),
                  child: const Text('Log value'),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: 48,
            child: Sparkline(
              values: state.kaizen.sevenDayTrend,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Weekly target ${Formatters.number(metric.weeklyTarget)} '
            '${metric.unit} · latest ${Formatters.number(metric.currentValue)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

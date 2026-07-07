import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../kaizen/presentation/widgets/growth_metric_chart.dart';
import '../../application/dashboard_state.dart';

/// The one active growth metric: today's value, weekly target, 7-day trend.
class GrowthMetricOverviewCard extends StatelessWidget {
  const GrowthMetricOverviewCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final metric = state.kaizen.activeMetric;
    if (metric == null) {
      return MetricCard(
        title: 'Active Growth Metric',
        supportText: 'No active metric. Point the engine at one hunt.',
        onTap: () => context.go('/kaizen'),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(
            onPressed: () => context.go('/kaizen'),
            child: const Text('Set active metric'),
          ),
        ),
      );
    }

    final todayValue = state.kaizen.todayMetricValue;
    return MetricCard(
      title: 'Active Growth Metric · ${metric.name}',
      badgeLabel: todayValue == null ? 'Log today' : 'Live',
      badgeLevel:
          todayValue == null ? StatusLevel.watch : StatusLevel.aligned,
      bigValue: todayValue == null
          ? '—'
          : '${Formatters.number(todayValue)} ${metric.unit}',
      supportText:
          'Weekly target ${Formatters.number(metric.weeklyTarget)} ${metric.unit} · latest ${Formatters.number(metric.currentValue)}',
      onTap: () => context.go('/kaizen'),
      child: SizedBox(
        height: 48,
        child: Sparkline(
          values: state.kaizen.sevenDayTrend,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

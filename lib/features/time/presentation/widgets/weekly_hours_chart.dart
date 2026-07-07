import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../application/time_controller.dart';

/// Stacked bar chart: total hours logged per week, with the Kaizen portion
/// highlighted, over the last several weeks.
class WeeklyHoursChart extends ConsumerWidget {
  const WeeklyHoursChart({super.key, this.kaizenWeeklyTarget});

  final double? kaizenWeeklyTarget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(weeklyHoursHistoryProvider);
    if (history == null) return const SizedBox.shrink();

    final hasData = history.any((p) => p.totalHours > 0);
    final maxTotal =
        history.fold<double>(0, (m, p) => p.totalHours > m ? p.totalHours : m);
    final maxY = maxTotal < 10 ? 10.0 : maxTotal * 1.15;

    return MetricCard(
      title: 'Weekly hours · last ${history.length} weeks',
      supportText: 'Kaizen highlighted vs everything else logged.',
      child: !hasData
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No time logged yet.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 170,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: theme.colorScheme.outlineVariant,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max) {
                                return const SizedBox.shrink();
                              }
                              return Text(value.round().toString(),
                                  style: theme.textTheme.labelSmall);
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final i = value.round();
                              if (i < 0 || i >= history.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  Formatters.shortDate(history[i].weekStart),
                                  style: theme.textTheme.labelSmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) =>
                              theme.colorScheme.inverseSurface,
                          getTooltipItem: (group, _, rod, __) {
                            final p = history[group.x];
                            return BarTooltipItem(
                              'Total ${Formatters.hours(p.totalHours)}\nKaizen ${Formatters.hours(p.kaizenHours)}',
                              TextStyle(
                                color: theme.colorScheme.onInverseSurface,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < history.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: history[i].totalHours,
                                width: 14,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3)),
                                rodStackItems: [
                                  BarChartRodStackItem(
                                    0,
                                    history[i].kaizenHours,
                                    AppColors.primary,
                                  ),
                                  BarChartRodStackItem(
                                    history[i].kaizenHours,
                                    history[i].totalHours,
                                    AppColors.neutral.withValues(alpha: 0.5),
                                  ),
                                ],
                                color: AppColors.neutral.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _legend(theme, AppColors.primary, 'Kaizen'),
                    const SizedBox(width: 16),
                    _legend(theme, AppColors.neutral.withValues(alpha: 0.5),
                        'Other logged'),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _legend(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

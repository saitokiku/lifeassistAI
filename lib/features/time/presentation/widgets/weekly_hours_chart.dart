import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../application/time_controller.dart';

/// Stacked bar history: total hours per week with the main-goal portion
/// highlighted, plus a dashed line marking the weekly goal-hours target.
class WeeklyHoursChart extends ConsumerWidget {
  const WeeklyHoursChart({super.key, this.goalWeeklyTarget});

  final double? goalWeeklyTarget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(weeklyHoursHistoryProvider);
    if (history == null) return const SkeletonCard(height: 260);

    final hasData = history.any((p) => p.totalHours > 0);
    final target = goalWeeklyTarget ?? 0;
    final showTarget = hasData && target > 0;
    final maxTotal =
        history.fold<double>(0, (m, p) => math.max(m, p.totalHours));
    final ceiling = math.max(maxTotal, showTarget ? target : 0);
    final maxY = ceiling < 10 ? 10.0 : ceiling * 1.15;
    final otherColor = AppColors.neutral.withValues(alpha: 0.5);

    return MetricCard(
      title: 'Weekly hours',
      supportText:
          'Last ${history.length} weeks · goal hours vs everything else.',
      child: !hasData
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No hours on the board yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
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
                      extraLinesData: showTarget
                          ? ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: target,
                                  color:
                                      AppColors.primary.withValues(alpha: 0.6),
                                  strokeWidth: 1,
                                  dashArray: [5, 4],
                                ),
                              ],
                            )
                          : null,
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
                              return Text(
                                value.round().toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
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
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
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
                              'Total ${Formatters.hours(p.totalHours)}\n'
                              'Main goal ${Formatters.hours(p.goalHours)}',
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
                                    history[i].goalHours,
                                    AppColors.primary,
                                  ),
                                  BarChartRodStackItem(
                                    history[i].goalHours,
                                    history[i].totalHours,
                                    otherColor,
                                  ),
                                ],
                                color: otherColor,
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
                    _swatch(theme, AppColors.primary, 'Main goal'),
                    const SizedBox(width: 16),
                    _swatch(theme, otherColor, 'Other logged'),
                    if (showTarget) ...[
                      const SizedBox(width: 16),
                      _dashSwatch(theme, 'Goal target'),
                    ],
                  ],
                ),
              ],
            ),
    );
  }

  Widget _swatch(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _dashSwatch(ThemeData theme, String label) {
    final color = AppColors.primary.withValues(alpha: 0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 2; i++) ...[
          Container(width: 5, height: 2, color: color),
          const SizedBox(width: 2),
        ],
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

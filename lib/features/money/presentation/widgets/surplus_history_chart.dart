import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../application/money_controller.dart';

/// Bar chart of monthly surplus (income − spend) over the last months.
/// Bars are colored by status; a dashed line marks the low surplus target.
class SurplusHistoryChart extends ConsumerWidget {
  const SurplusHistoryChart({super.key, required this.targetSurplusLow});

  final double targetSurplusLow;

  static final _monthFmt = DateFormat('MMM');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(monthlySurplusHistoryProvider);
    if (history == null) return const SizedBox.shrink();

    final surpluses = history.map((p) => p.surplus).toList();
    var maxV = surpluses.reduce((a, b) => a > b ? a : b);
    var minV = surpluses.reduce((a, b) => a < b ? a : b);
    if (targetSurplusLow > maxV) maxV = targetSurplusLow;
    maxV = maxV <= 0 ? 100 : maxV * 1.15;
    minV = minV >= 0 ? 0 : minV * 1.15;

    return MetricCard(
      title: 'Monthly surplus · last ${history.length} months',
      supportText:
          'Income − actual spend per month. Dashed line = ${Formatters.money(targetSurplusLow)} floor.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxV,
                minY: minV,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: value == 0
                        ? theme.colorScheme.outline
                        : theme.colorScheme.outlineVariant,
                    strokeWidth: value == 0 ? 1.2 : 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: targetSurplusLow,
                      color: AppColors.watch.withValues(alpha: 0.8),
                      strokeWidth: 1.2,
                      dashArray: [6, 4],
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        return Text(Formatters.compact(value),
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
                          child: Text(_monthFmt.format(history[i].month),
                              style: theme.textTheme.labelSmall),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                    getTooltipItem: (group, _, rod, __) {
                      final p = history[group.x];
                      return BarTooltipItem(
                        '${Formatters.moneySigned(p.surplus)}${p.isPartial ? ' (so far)' : ''}\nspent ${Formatters.money(p.spend)}',
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
                          toY: history[i].surplus,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                          color: _colorFor(history[i])
                              .withValues(alpha: history[i].isPartial ? 0.55 : 1),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(MonthlySurplusPoint p) {
    if (p.surplus < 0) return AppColors.critical;
    if (p.surplus < targetSurplusLow) return AppColors.watch;
    return AppColors.aligned;
  }
}

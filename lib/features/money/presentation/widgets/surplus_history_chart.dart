import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../application/money_controller.dart';

/// Bar chart of monthly surplus (income − spend) over the last months.
/// Bars carry status colors; the in-progress month is outlined, not solid,
/// because it hasn't finished happening yet.
class SurplusHistoryChart extends ConsumerWidget {
  const SurplusHistoryChart({super.key, required this.targetSurplusLow});

  final double targetSurplusLow;

  static final _monthFmt = DateFormat('MMM');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(monthlySurplusHistoryProvider);
    if (history == null) {
      // Hold the card's height while the stream warms up so the page
      // doesn't jump when the chart arrives.
      return const SkeletonCard(height: 288);
    }

    final surpluses = history.map((p) => p.surplus).toList();
    var maxV = surpluses.reduce((a, b) => a > b ? a : b);
    var minV = surpluses.reduce((a, b) => a < b ? a : b);
    if (targetSurplusLow > maxV) maxV = targetSurplusLow;
    maxV = maxV <= 0 ? 100 : maxV * 1.15;
    minV = minV >= 0 ? 0 : minV * 1.15;

    return MetricCard(
      title: 'Surplus · last ${history.length} months',
      supportText:
          'Dashed line marks the ${Formatters.money(targetSurplusLow)} floor.',
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
                      color: AppColors.watch.withValues(alpha: 0.7),
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
                        return Text(
                          Formatters.compact(value),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.textTertiary,
                            letterSpacing: 0,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.round();
                        if (i < 0 || i >= history.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _monthFmt.format(history[i].month),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.textTertiary,
                              letterSpacing: 0,
                            ),
                          ),
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
                          fontFeatures: const [FontFeature.tabularFigures()],
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
                        if (history[i].isPartial)
                          // Outlined: this month is still accumulating.
                          BarChartRodData(
                            toY: history[i].surplus,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                            color:
                                _colorFor(history[i]).withValues(alpha: 0.18),
                            borderSide: BorderSide(
                              color: _colorFor(history[i]),
                              width: 1.4,
                            ),
                          )
                        else
                          BarChartRodData(
                            toY: history[i].surplus,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                            color: _colorFor(history[i]),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Outlined bar is this month, still in motion. Assumes current income across past months.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.textTertiary,
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

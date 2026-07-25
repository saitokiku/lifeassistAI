import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/haptics.dart';
import '../../domain/growth_metric_entry.dart';

/// Line chart of the active metric's dated entries with a 30/90-day toggle
/// and the weekly target drawn as a dashed reference line.
class MetricHistoryChart extends StatefulWidget {
  const MetricHistoryChart({
    super.key,
    required this.entries,
    required this.unit,
    this.weeklyTarget,
    this.today,
  });

  /// Newest-first list of entries (as provided by the repository).
  final List<GrowthMetricEntry> entries;
  final String unit;
  final double? weeklyTarget;

  /// The app's ticking "today"; falls back to the device clock.
  final DateTime? today;

  @override
  State<MetricHistoryChart> createState() => _MetricHistoryChartState();
}

class _MetricHistoryChartState extends State<MetricHistoryChart> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = AppDateUtils.dateOnly(widget.today ?? DateTime.now());
    final start = AppDateUtils.subtractDays(today, _days - 1);

    final inRange = widget.entries
        .where((e) => !AppDateUtils.parseDateKey(e.date).isBefore(start))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SegmentedButton<int>(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 30, label: Text('30d')),
              ButtonSegment(value: 90, label: Text('90d')),
            ],
            selected: {_days},
            onSelectionChanged: (s) {
              Haptics.select();
              setState(() => _days = s.first);
            },
          ),
        ),
        const SizedBox(height: AppSpace.md),
        SizedBox(
          height: 180,
          child: inRange.length < 2
              ? Center(
                  child: Text(
                    inRange.isEmpty
                        ? 'No entries in the last $_days days.'
                        : 'Log a few more days to see a trend.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : _buildChart(context, inRange, start),
        ),
      ],
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<GrowthMetricEntry> inRange,
    DateTime start,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spots = [
      for (final e in inRange)
        FlSpot(
          AppDateUtils.daysBetween(start, AppDateUtils.parseDateKey(e.date))
              .toDouble(),
          e.value,
        ),
    ];

    final target = widget.weeklyTarget;
    final hasTarget = target != null && target > 0;

    final values = spots.map((s) => s.y).toList();
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    if (hasTarget) maxY = math.max(maxY, target);
    if (minY == maxY) {
      minY = minY - 1;
      maxY = maxY + 1;
    }
    final pad = (maxY - minY) * 0.12;
    minY = (minY - pad).clamp(0, double.infinity).toDouble();
    if (minY == maxY) minY = 0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_days - 1).toDouble(),
        minY: minY,
        maxY: maxY + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 3).clamp(0.001, double.infinity),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: scheme.outlineFaint, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: hasTarget
            ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: target,
                    color: scheme.textTertiary,
                    strokeWidth: 1,
                    dashArray: const [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.textTertiary,
                      ),
                      labelResolver: (_) =>
                          'Target ${Formatters.compact(target)}',
                    ),
                  ),
                ],
              )
            : const ExtraLinesData(),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  Formatters.compact(value),
                  style: theme.textTheme.labelSmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              // Four date ticks across the range, first and last included.
              interval: math.max(1, (_days - 1) / 3),
              getTitlesWidget: (value, meta) {
                final date = AppDateUtils.addDays(start, value.round());
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    Formatters.shortDate(date),
                    style: theme.textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${Formatters.number(s.y)} ${widget.unit}\n'
                  '${Formatters.shortDate(AppDateUtils.addDays(start, s.x.round()))}',
                  TextStyle(
                    color: scheme.onInverseSurface,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: spots.length <= 31,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 2.5,
                color: AppColors.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/storage/app_database.dart';

/// Line chart of an active metric's dated entries with a 30/90-day toggle.
class MetricHistoryChart extends StatefulWidget {
  const MetricHistoryChart({
    super.key,
    required this.entries,
    required this.unit,
    this.weeklyTarget,
  });

  /// Newest-first list of entries (as provided by the repository).
  final List<GrowthMetricEntry> entries;
  final String unit;
  final double? weeklyTarget;

  @override
  State<MetricHistoryChart> createState() => _MetricHistoryChartState();
}

class _MetricHistoryChartState extends State<MetricHistoryChart> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = AppDateUtils.dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: _days - 1));

    final inRange = widget.entries
        .where((e) => !AppDateUtils.parseDateKey(e.date).isBefore(start))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('History',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            SegmentedButton<int>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(value: 30, label: Text('30d')),
                ButtonSegment(value: 90, label: Text('90d')),
              ],
              selected: {_days},
              onSelectionChanged: (s) => setState(() => _days = s.first),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: inRange.length < 2
              ? Center(
                  child: Text(
                    inRange.isEmpty
                        ? 'No entries in the last $_days days.'
                        : 'Log a few more days to see a trend.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              : _buildChart(context, inRange, start),
        ),
      ],
    );
  }

  Widget _buildChart(
      BuildContext context, List<GrowthMetricEntry> inRange, DateTime start) {
    final theme = Theme.of(context);
    final spots = [
      for (final e in inRange)
        FlSpot(
          AppDateUtils.parseDateKey(e.date).difference(start).inDays.toDouble(),
          e.value,
        ),
    ];

    final values = spots.map((s) => s.y).toList();
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
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
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
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
                return Text(Formatters.compact(value),
                    style: theme.textTheme.labelSmall);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (_days - 1).toDouble(),
              getTitlesWidget: (value, meta) {
                final date = start.add(Duration(days: value.round()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(Formatters.shortDate(date),
                      style: theme.textTheme.labelSmall),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${Formatters.number(s.y)} ${widget.unit}\n${Formatters.shortDate(start.add(Duration(days: s.x.round())))}',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
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

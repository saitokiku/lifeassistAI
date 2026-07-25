import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/weekdays.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../application/habits_state.dart';

/// GitHub-style consistency heatmap: one column per week (oldest left),
/// one row per weekday, cell intensity = share of scheduled habits done
/// that day. Off-schedule days with nothing due stay blank, not guilty.
class HabitHeatmap extends StatelessWidget {
  const HabitHeatmap({super.key, required this.state, this.weeks = 16});

  final HabitsState state;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = state.today;
    final firstMonday =
        AppDateUtils.subtractDays(AppDateUtils.startOfWeek(today), 7 * (weeks - 1));

    // done/scheduled per day key.
    final doneByDay = <String, int>{};
    final scheduledByDay = <String, int>{};
    for (final h in state.habits) {
      final logged = h.loggedDays;
      for (var day = firstMonday;
          !day.isAfter(today);
          day = AppDateUtils.addDays(day, 1)) {
        if (!WeekdayMask.isDueOn(h.habit.weekdays, day)) continue;
        final key = AppDateUtils.dateKey(day);
        scheduledByDay[key] = (scheduledByDay[key] ?? 0) + 1;
        if (logged.contains(key)) {
          doneByDay[key] = (doneByDay[key] ?? 0) + 1;
        }
      }
    }

    Color cellColor(DateTime day) {
      if (day.isAfter(today)) return Colors.transparent;
      final key = AppDateUtils.dateKey(day);
      final scheduled = scheduledByDay[key] ?? 0;
      if (scheduled == 0) return scheme.elevated;
      final ratio = (doneByDay[key] ?? 0) / scheduled;
      if (ratio <= 0) return scheme.elevated;
      return AppColors.primary
          .withValues(alpha: 0.18 + 0.72 * ratio.clamp(0.0, 1.0));
    }

    return MetricCard(
      title: 'Consistency · last $weeks weeks',
      supportText: 'Darker = more of that day\'s habits done.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 3.0;
          final cell =
              ((constraints.maxWidth - gap * (weeks - 1)) / weeks)
                  .clamp(6.0, 14.0);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var weekday = 0; weekday < 7; weekday++) ...[
                if (weekday > 0) const SizedBox(height: gap),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var week = 0; week < weeks; week++) ...[
                      if (week > 0) const SizedBox(width: gap),
                      Container(
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(
                          color: cellColor(AppDateUtils.addDays(
                              firstMonday, week * 7 + weekday)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

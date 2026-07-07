import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/dashboard_state.dart';

/// Kaizen hours this week vs the editable weekly target.
class KaizenOverviewCard extends StatelessWidget {
  const KaizenOverviewCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final hours = state.time.kaizenHoursThisWeek;
    final target = state.time.kaizenWeeklyTarget;
    final status = state.kaizenHoursStatus;

    return MetricCard(
      title: 'Kaizen Hours This Week',
      badgeLabel: ScoreUtils.kaizenHoursLabel(hours),
      badgeLevel: status,
      bigValue: Formatters.hours(hours),
      supportText:
          'Target ${Formatters.hours(target)} · ${Formatters.hours((target - hours).clamp(0, double.infinity))} remaining',
      onTap: () => context.go('/kaizen'),
      child: LabeledProgressBar(
        progress: target <= 0 ? 0 : hours / target,
        color: status.color,
      ),
    );
  }
}

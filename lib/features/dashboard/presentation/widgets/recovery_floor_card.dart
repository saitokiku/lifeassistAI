import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/dashboard_state.dart';

/// Decompress hours this week vs the recovery floor.
class RecoveryFloorCard extends StatelessWidget {
  const RecoveryFloorCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final hours = state.time.recoveryHoursThisWeek;
    final target = state.time.recoveryWeeklyTarget;
    final status = state.recoveryStatus;

    return MetricCard(
      title: 'Recovery Floor',
      badgeLabel: ScoreUtils.recoveryLabel(hours),
      badgeLevel: status,
      bigValue: Formatters.hours(hours),
      supportText:
          'Target ${Formatters.hours(target)} this week · ${AppCopy.recoveryLoadBearing}',
      onTap: () => context.go('/time'),
      child: LabeledProgressBar(
        progress: target <= 0 ? 0 : hours / target,
        color: status.color,
      ),
    );
  }
}

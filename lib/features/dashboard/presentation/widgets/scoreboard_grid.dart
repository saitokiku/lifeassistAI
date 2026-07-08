import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../shared/status_display.dart';
import '../../../../shared/widgets/stat_tile.dart';
import '../../application/dashboard_state.dart';

/// Four tiles, one glance: Kaizen hours, surplus, recovery, streak.
class ScoreboardGrid extends StatelessWidget {
  const ScoreboardGrid({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final time = state.time;
    final snapshot = state.money.snapshot;
    final streak = state.kaizen.experimentStreak;

    final kaizenTarget = time.kaizenWeeklyTarget;
    final recoveryTarget = time.recoveryWeeklyTarget;

    final tiles = [
      StatTile(
        label: 'Kaizen hours',
        value: Formatters.hours(time.kaizenHoursThisWeek),
        caption: 'of ${Formatters.hours(kaizenTarget)} this week',
        level: StatusDisplay.hoursStatus(time.kaizenHoursThisWeek, kaizenTarget),
        progress: kaizenTarget <= 0
            ? 0
            : time.kaizenHoursThisWeek / kaizenTarget,
        onTap: () => context.go('/time'),
      ),
      StatTile(
        label: 'Surplus',
        value: Formatters.moneySigned(snapshot.projectedSurplus),
        caption: 'target ${Formatters.money(snapshot.targetSurplusLow)}+',
        level: ScoreUtils.surplusStatus(
          projectedSurplus: snapshot.projectedSurplus,
          targetSurplusLow: snapshot.targetSurplusLow,
        ),
        onTap: () => context.go('/money'),
      ),
      StatTile(
        label: 'Recovery',
        value: Formatters.hours(time.recoveryHoursThisWeek),
        caption: 'floor ${Formatters.hours(recoveryTarget)}',
        level: ScoreUtils.recoveryStatus(time.recoveryHoursThisWeek),
        progress: recoveryTarget <= 0
            ? 0
            : time.recoveryHoursThisWeek / recoveryTarget,
        onTap: () => context.go('/time'),
      ),
      StatTile(
        label: 'Streak',
        value: '$streak day${streak == 1 ? '' : 's'}',
        caption: 'experiment streak',
        icon: Icons.local_fire_department,
        level: streak > 0 ? StatusLevel.aligned : StatusLevel.neutral,
        onTap: () => context.go('/kaizen'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpace.cardGap;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }
}

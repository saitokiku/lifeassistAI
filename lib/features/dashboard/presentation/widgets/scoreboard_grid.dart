import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../shared/widgets/stat_tile.dart';
import '../../../settings/domain/user_settings.dart';
import '../../application/dashboard_state.dart';

/// The week's key numbers at a glance. Tiles appear only for areas the
/// user tracks — an empty grid renders nothing at all.
class ScoreboardGrid extends StatelessWidget {
  const ScoreboardGrid({super.key, required this.state});

  final DashboardState state;

  /// Whether any tile would render (the screen hides the header otherwise).
  static bool hasTiles(DashboardState state) =>
      _tilesFor(state, null).isNotEmpty;

  static List<StatTile> _tilesFor(
    DashboardState state,
    BuildContext? context,
  ) {
    final time = state.time;
    final snapshot = state.money.snapshot;
    final streak = state.focus.actionStreak;
    final goalTarget = time.goalWeeklyTarget;
    final recoveryTarget = time.recoveryWeeklyTarget;
    final goalTitle = state.goal?.title;

    void go(String route) {
      if (context != null) context.go(route);
    }

    return [
      if (state.showsArea(DashboardArea.time) &&
          state.goalActive &&
          goalTarget > 0)
        StatTile(
          label: goalTitle == null ? 'Goal hours' : '$goalTitle hours',
          value: Formatters.hours(time.goalHoursThisWeek),
          caption: 'of ${Formatters.hours(goalTarget)} this week',
          level: ScoreUtils.goalHoursStatus(time.goalHoursThisWeek, goalTarget),
          progress: time.goalHoursThisWeek / goalTarget,
          onTap: () => go('/time'),
        ),
      if (state.showsArea(DashboardArea.money) && state.settings.hasIncome)
        StatTile(
          label: 'Surplus',
          value: Formatters.moneySigned(snapshot.projectedSurplus),
          caption: snapshot.targetSurplusLow > 0
              ? 'target ${Formatters.money(snapshot.targetSurplusLow)}+'
              : 'projected this month',
          level: ScoreUtils.surplusStatus(
            projectedSurplus: snapshot.projectedSurplus,
            targetSurplusLow: snapshot.targetSurplusLow,
          ),
          onTap: () => go('/money'),
        ),
      if (state.showsArea(DashboardArea.time) && recoveryTarget > 0)
        StatTile(
          label: 'Downtime',
          value: Formatters.hours(time.recoveryHoursThisWeek),
          caption: 'of ${Formatters.hours(recoveryTarget)} planned',
          level: ScoreUtils.recoveryStatus(time.recoveryHoursThisWeek),
          progress: time.recoveryHoursThisWeek / recoveryTarget,
          onTap: () => go('/time'),
        ),
      if (state.goalActive)
        StatTile(
          label: 'Streak',
          value: '$streak day${streak == 1 ? '' : 's'}',
          caption: 'daily steps in a row',
          icon: Icons.local_fire_department,
          level: streak > 0 ? StatusLevel.aligned : StatusLevel.neutral,
          onTap: () => go('/focus'),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _tilesFor(state, context);
    if (tiles.isEmpty) return const SizedBox.shrink();

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

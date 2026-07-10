import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../../../shared/widgets/progress_ring.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../application/dashboard_state.dart';

/// Greeting (by name when known), date, the user's line if they wrote one,
/// and the day score ring. Tapping the ring opens the score breakdown.
class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key, required this.state});

  final DashboardState state;

  String get _greeting {
    final hour = state.time.now.hour;
    final name = state.settings.displayName;
    final base = hour < 5
        ? 'Up late'
        : hour < 12
            ? 'Good morning'
            : hour < 17
                ? 'Good afternoon'
                : 'Good evening';
    return name.isEmpty ? '$base.' : '$base, $name.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = state.focusScore;
    final status = ScoreUtils.focusScoreStatus(score.total);
    final date = DateFormat('EEEE, MMM d').format(state.time.now);
    final line = state.settings.philosophyText.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpace.xs),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (line.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  line,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.textTertiary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (state.showScore) ...[
          const SizedBox(width: AppSpace.lg),
          Semantics(
            label: "Today's score ${score.total} of 100. Tap for breakdown.",
            button: true,
            child: GestureDetector(
              onTap: () => _showBreakdown(context),
              child: ProgressRing(
                progress: score.total / 100,
                color: status.color,
                size: 52,
                strokeWidth: 5,
                center: Text(
                  '${score.total}',
                  style: theme.textTheme.numberMedium.copyWith(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showBreakdown(BuildContext context) {
    final score = state.focusScore;
    final status = ScoreUtils.focusScoreStatus(score.total);
    final label = ScoreUtils.focusScoreLabel(score.total);
    final goalTitle = state.goal?.title ?? 'your goal';

    showAppSheet<void>(
      context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return AppSheet(
          title: "Today's score",
          subtitle: 'Five honest signals of whether today moved you forward.',
          children: [
            Row(
              children: [
                ProgressRing(
                  progress: score.total / 100,
                  color: status.color,
                  size: 84,
                  strokeWidth: 8,
                  center: Text(
                    '${score.total}',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(width: AppSpace.xl),
                StatusBadge(label: label, level: status),
              ],
            ),
            const SizedBox(height: AppSpace.xxl),
            _part(theme, 'Hours on $goalTitle', score.goalScore, 35),
            _part(theme, 'Daily step', score.actionScore, 20),
            // Hidden areas are excluded from the score, so they don't
            // appear here either.
            if (score.moneyScore case final money?)
              _part(theme, 'Money pace', money, 15),
            if (score.healthScore case final health?)
              _part(theme, 'Exercise or meditation', health, 15),
            if (score.recoveryScore case final recovery?)
              _part(theme, 'Downtime', recovery, 15),
          ],
        );
      },
    );
  }

  Widget _part(ThemeData theme, String label, double value, int max) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              Text(
                '${value.round()}/$max',
                style: theme.textTheme.numberBody.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LabeledProgressBar(
            progress: max <= 0 ? 0 : value / max,
            color: value >= max
                ? AppColors.aligned
                : value > 0
                    ? AppColors.watch
                    : AppColors.neutral,
            height: 5,
          ),
        ],
      ),
    );
  }
}

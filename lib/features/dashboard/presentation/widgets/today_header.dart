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

/// Greeting, date + philosophy line, and the compact focus ring.
/// Tapping the ring opens the score breakdown.
class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key, required this.state});

  final DashboardState state;

  String get _greeting {
    final hour = state.time.now.hour;
    if (hour < 5) return 'Late shift.';
    if (hour < 12) return 'Good morning.';
    if (hour < 17) return 'Good afternoon.';
    return 'Good evening.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = state.focusScore;
    final status = ScoreUtils.focusScoreStatus(score.total);
    final date = DateFormat('EEEE, MMM d').format(state.time.now);

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
              const SizedBox(height: 2),
              Text(
                state.identity.philosophyText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.textTertiary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.lg),
        Semantics(
          label: 'Focus score ${score.total} of 100. Tap for breakdown.',
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
    );
  }

  void _showBreakdown(BuildContext context) {
    final score = state.focusScore;
    final status = ScoreUtils.focusScoreStatus(score.total);
    final label = ScoreUtils.focusScoreLabel(score.total);

    showAppSheet<void>(
      context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return AppSheet(
          title: 'Focus integrity',
          subtitle: 'Five signals, one honest number. Drift shows up here first.',
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
            _part(theme, 'Kaizen hours', score.kaizenScore, 35),
            _part(theme, 'Daily experiment', score.experimentScore, 20),
            _part(theme, 'Money pace', score.moneyScore, 15),
            _part(theme, 'Exercise or meditation', score.healthScore, 15),
            _part(theme, 'Recovery floor', score.recoveryScore, 15),
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

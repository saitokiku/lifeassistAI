import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/progress_ring.dart';
import '../../application/dashboard_state.dart';

/// Focus Integrity Score 0–100 with its five-part breakdown.
class FocusIntegrityCard extends StatelessWidget {
  const FocusIntegrityCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = state.focusScore;
    final total = score.total;
    final status = ScoreUtils.focusScoreStatus(total);

    return MetricCard(
      title: 'Focus Integrity Score',
      badgeLabel: ScoreUtils.focusScoreLabel(total),
      badgeLevel: status,
      child: Row(
        children: [
          ProgressRing(
            progress: total / 100,
            color: status.color,
            size: 88,
            center: Text(
              '$total',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                _part(theme, 'Kaizen hours', score.kaizenScore, 35),
                _part(theme, 'Experiment', score.experimentScore, 20),
                _part(theme, 'Money pace', score.moneyScore, 15),
                _part(theme, 'Exercise/meditation', score.healthScore, 15),
                _part(theme, 'Recovery', score.recoveryScore, 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _part(ThemeData theme, String label, double value, int max) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Text(
            '${value.round()}/$max',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

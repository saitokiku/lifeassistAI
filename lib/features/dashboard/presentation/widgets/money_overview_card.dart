import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../application/dashboard_state.dart';

/// Monthly surplus: income, month-to-date spend, projections, target range.
class MoneyOverviewCard extends StatelessWidget {
  const MoneyOverviewCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.money.snapshot;
    final theme = Theme.of(context);

    return MetricCard(
      title: 'Monthly Surplus',
      badgeLabel: ScoreUtils.surplusLabel(
        projectedSurplus: snapshot.projectedSurplus,
        targetSurplusLow: snapshot.targetSurplusLow,
        targetSurplusHigh: snapshot.targetSurplusHigh,
      ),
      badgeLevel: state.surplusStatus,
      bigValue: Formatters.moneySigned(snapshot.projectedSurplus),
      supportText:
          'Projected · target ${Formatters.money(snapshot.targetSurplusLow)}–${Formatters.money(snapshot.targetSurplusHigh)}',
      onTap: () => context.go('/money'),
      child: Column(
        children: [
          _row(theme, 'Net income', Formatters.money(snapshot.monthlyNetIncome)),
          _row(theme, 'Spend month-to-date',
              Formatters.money(snapshot.spendSoFar)),
          _row(theme, 'Projected spend',
              Formatters.money(snapshot.projectedSpend)),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }
}

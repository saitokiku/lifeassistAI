import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../domain/monthly_money_snapshot.dart';

/// Surplus headline for the Money screen.
class SurplusCard extends StatelessWidget {
  const SurplusCard({super.key, required this.snapshot, this.onEditIncome});

  final MonthlyMoneySnapshot snapshot;
  final VoidCallback? onEditIncome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MetricCard(
      title: 'Projected surplus this month',
      badgeLabel: ScoreUtils.surplusLabel(
        projectedSurplus: snapshot.projectedSurplus,
        targetSurplusLow: snapshot.targetSurplusLow,
        targetSurplusHigh: snapshot.targetSurplusHigh,
      ),
      badgeLevel: ScoreUtils.surplusStatus(
        projectedSurplus: snapshot.projectedSurplus,
        targetSurplusLow: snapshot.targetSurplusLow,
      ),
      bigValue: Formatters.moneySigned(snapshot.projectedSurplus),
      supportText: AppCopy.moneyScoreboard,
      child: Column(
        children: [
          _row(theme, 'Net monthly income',
              Formatters.money(snapshot.monthlyNetIncome)),
          _row(theme, 'Spend month-to-date',
              Formatters.money(snapshot.spendSoFar)),
          _row(theme, 'Projected spend',
              Formatters.money(snapshot.projectedSpend)),
          _row(
              theme,
              'Target surplus',
              '${Formatters.money(snapshot.targetSurplusLow)}–${Formatters.money(snapshot.targetSurplusHigh)}'),
          _row(theme, 'Annual savings projection',
              Formatters.moneySigned(snapshot.annualSavingsProjection)),
          if (onEditIncome != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onEditIncome,
                child: const Text('Edit income & targets'),
              ),
            ),
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

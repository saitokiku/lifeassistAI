import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../domain/monthly_money_snapshot.dart';

/// Where the surplus goes: Roth IRA pace plus brokerage and savings
/// balances. All manual — one sheet updates the lot.
class FreedomAccountsCard extends StatelessWidget {
  const FreedomAccountsCard({
    super.key,
    required this.snapshot,
    this.onEdit,
  });

  final MonthlyMoneySnapshot snapshot;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasIraTarget = snapshot.rothIraAnnualTarget > 0;

    return MetricCard(
      title: 'Freedom accounts',
      supportText: 'Manual balances. Update monthly.',
      trailing: onEdit == null
          ? null
          : TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Edit'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasIraTarget)
            LabeledProgressBar(
              progress: snapshot.rothIraProgress,
              color: AppColors.primary,
              leading: 'Roth IRA',
              trailing:
                  '${Formatters.money(snapshot.rothIraContributed)} of ${Formatters.money(snapshot.rothIraAnnualTarget)}',
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text('Roth IRA', style: theme.textTheme.bodySmall),
                ),
                Text(
                  'no target set',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.textTertiary,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpace.md),
          _row(theme, 'Brokerage', Formatters.money(snapshot.brokerageBalance)),
          const SizedBox(height: 6),
          _row(theme, 'Savings', Formatters.money(snapshot.savingsBalance)),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(value, style: theme.textTheme.numberBody),
      ],
    );
  }
}

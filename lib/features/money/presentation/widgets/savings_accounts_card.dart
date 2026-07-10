import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../domain/monthly_money_snapshot.dart';

/// Where the surplus goes: retirement pace plus brokerage and savings
/// balances. All manual — one sheet updates the lot.
class SavingsAccountsCard extends StatelessWidget {
  const SavingsAccountsCard({
    super.key,
    required this.snapshot,
    this.onEdit,
  });

  final MonthlyMoneySnapshot snapshot;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRetirementTarget = snapshot.retirementAnnualTarget > 0;

    return MetricCard(
      title: 'Savings & investing',
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
          if (hasRetirementTarget)
            LabeledProgressBar(
              progress: snapshot.retirementProgress,
              color: AppColors.primary,
              leading: 'Retirement',
              trailing:
                  '${Formatters.money(snapshot.retirementContributed)} of ${Formatters.money(snapshot.retirementAnnualTarget)}',
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text('Retirement', style: theme.textTheme.bodySmall),
                ),
                Text(
                  'no yearly target set',
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

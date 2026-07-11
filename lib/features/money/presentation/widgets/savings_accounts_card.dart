import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../domain/monthly_money_snapshot.dart';

/// Retirement pace for the year. Account balances moved to the real
/// Accounts card; the pre-v3 brokerage/savings numbers live on only as
/// migration inputs.
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
      title: 'Retirement pace',
      supportText: 'Contributions this year against the target.',
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
      child: hasRetirementTarget
          ? LabeledProgressBar(
              progress: snapshot.retirementProgress,
              color: AppColors.primary,
              leading: 'Retirement',
              trailing:
                  '${Formatters.money(snapshot.retirementContributed)} of ${Formatters.money(snapshot.retirementAnnualTarget)}',
            )
          : Row(
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
    );
  }
}

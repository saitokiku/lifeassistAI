import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/dashboard_state.dart';

/// The long game, condensed: annual projection, Roth IRA, freedom target.
class FreedomProgressCard extends StatelessWidget {
  const FreedomProgressCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = state.money.snapshot;
    final target = state.identity.primaryFreedomTarget;

    return AppCard(
      onTap: () => context.go('/identity'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'FREEDOM',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.textTertiary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            Formatters.moneySigned(snapshot.annualSavingsProjection),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 2),
          Text(
            'projected savings this year',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          LabeledProgressBar(
            progress: snapshot.rothIraProgress,
            color: AppColors.primary,
            leading: 'Roth IRA',
            trailing:
                '${Formatters.money(snapshot.rothIraContributed)} of ${Formatters.money(snapshot.rothIraAnnualTarget)}',
          ),
          if (target != null) ...[
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    target.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${Formatters.money(target.currentMonthlyPassiveIncome)} / ${Formatters.money(target.targetMonthlyPassiveIncome)} passive',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

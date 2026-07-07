import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/dashboard_state.dart';

/// Freedom progress: surplus, annual projection, Roth IRA, freedom target.
class FreedomProgressCard extends StatelessWidget {
  const FreedomProgressCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = state.money.snapshot;
    final target = state.identity.primaryFreedomTarget;

    return MetricCard(
      title: 'Freedom Progress',
      supportText: 'Money is the scoreboard. Freedom is the goal.',
      onTap: () => context.go('/identity'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(theme, 'Annual savings projection',
              Formatters.moneySigned(snapshot.annualSavingsProjection)),
          _row(
              theme,
              'Roth IRA',
              '${Formatters.money(snapshot.rothIraContributed)} of ${Formatters.money(snapshot.rothIraAnnualTarget)}'),
          const SizedBox(height: 4),
          LabeledProgressBar(
            progress: snapshot.rothIraProgress,
            color: AppColors.primary,
            leading: 'Roth IRA progress',
            trailing: Formatters.percent(snapshot.rothIraProgress),
          ),
          if (target != null) ...[
            const SizedBox(height: 10),
            Text(
              target.title,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            _row(
                theme,
                'Passive income target',
                '${Formatters.money(target.currentMonthlyPassiveIncome)} / ${Formatters.money(target.targetMonthlyPassiveIncome)}/mo'),
            _row(
                theme,
                'Liquid net worth target',
                '${Formatters.money(target.currentLiquidNetWorth)} / ${Formatters.money(target.targetLiquidNetWorth)}'),
          ],
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

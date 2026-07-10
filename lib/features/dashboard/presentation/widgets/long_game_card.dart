import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../../identity/application/identity_controller.dart';
import '../../application/dashboard_state.dart';

/// The long game, condensed: this year's savings pace, retirement progress,
/// and the long-term target. Lives on Money; this is the one-glance summary.
class LongGameCard extends ConsumerWidget {
  const LongGameCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snapshot = state.money.snapshot;
    final target = ref.watch(freedomTargetsProvider).valueOrNull?.firstOrNull;

    final hasRetirement = snapshot.retirementAnnualTarget > 0;
    // Nothing long-term is configured yet — stay out of the way.
    if (!state.settings.hasIncome && !hasRetirement && target == null) {
      return const SizedBox.shrink();
    }

    return AppCard(
      onTap: () => context.go('/money'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'THE LONG GAME',
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
          if (state.settings.hasIncome) ...[
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
          ],
          if (hasRetirement) ...[
            const SizedBox(height: AppSpace.lg),
            LabeledProgressBar(
              progress: snapshot.retirementProgress,
              color: AppColors.primary,
              leading: 'Retirement',
              trailing:
                  '${Formatters.money(snapshot.retirementContributed)} of ${Formatters.money(snapshot.retirementAnnualTarget)}',
            ),
          ],
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

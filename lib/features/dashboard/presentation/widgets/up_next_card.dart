import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../focus/domain/main_goal.dart';
import '../../../focus/presentation/widgets/action_log_form.dart';
import '../../../focus/presentation/widgets/growth_metric_entry_form.dart';
import '../../../focus/presentation/widgets/main_goal_editor.dart';
import '../../../settings/domain/user_settings.dart';
import '../../application/dashboard_state.dart';

/// The hero of the Today screen: the one thing most worth doing right now,
/// with a direct action — quieter signals sit below it.
class UpNextCard extends StatelessWidget {
  const UpNextCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hero = _hero(context);
    final secondary = _secondaryLines(context);

    return AppCard(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UP NEXT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.brandLabel,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            hero.text,
            style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
          ),
          if (hero.actionLabel != null) ...[
            const SizedBox(height: AppSpace.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 40),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                ),
                onPressed: hero.onTap,
                child: Text(hero.actionLabel!),
              ),
            ),
          ],
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            for (final line in secondary) _secondaryLine(context, line),
          ],
        ],
      ),
    );
  }

  /// The hero directive for the resolved [UpNextKind].
  _Directive _hero(BuildContext context) {
    final goalTitle = state.goal?.title;
    final milestone = state.focus.nextMilestone;
    final metric = state.focus.activeMetric;

    switch (state.upNext) {
      case UpNextKind.setGoal:
        return _Directive(
          text: 'Pick the one thing you most want to move toward — '
              'the app organizes itself around it.',
          actionLabel: 'Set your main goal',
          onTap: () => MainGoalEditor.show(context),
        );
      case UpNextKind.goalCompleted:
        return _Directive(
          text: 'You finished ${goalTitle ?? 'your goal'}. Take the win — '
              "then choose what's next when you're ready.",
          actionLabel: 'Celebrate on Focus',
          onTap: () => context.go('/focus'),
        );
      case UpNextKind.moneyCritical:
        return _Directive(
          text: state.money.snapshot.projectedSurplus < 0
              ? 'Spending is projected past income this month. Worth a look '
                  'before anything else.'
              : 'A budget line needs attention before it grows.',
          actionLabel: 'Review money',
          onTap: () => context.go('/money'),
        );
      case UpNextKind.logAction:
        return _Directive(
          text: 'Take one small step toward $goalTitle today — '
              'then log how it went.',
          actionLabel: 'Log a step',
          onTap: () => ActionLogForm.show(context),
        );
      case UpNextKind.logGoalTime:
        return _Directive(
          text: 'Hours on $goalTitle are behind this week. '
              'Even one focused block helps.',
          actionLabel: 'Log time',
          onTap: () => context.go('/time'),
        );
      case UpNextKind.logMetric:
        return _Directive(
          text: "Today's step is in. Log ${metric?.name ?? 'your measure'} "
              'to keep the trend honest.',
          actionLabel: 'Log value',
          onTap: metric == null
              ? () => context.go('/focus')
              : () => GrowthMetricEntryForm.show(context, metric: metric),
        );
      case UpNextKind.protectRecovery:
        return _Directive(
          text: 'No downtime logged this week. Rest is part of the plan — '
              'put one block on the board.',
          actionLabel: 'Log downtime',
          onTap: () => context.go('/time'),
        );
      case UpNextKind.reviewIdeas:
        final n = state.ideasDueForReview;
        return _Directive(
          text: '$n idea${n == 1 ? ' is' : 's are'} done cooling. '
              'Decide: ignore, later, or fold into the plan.',
          actionLabel: 'Review ideas',
          onTap: () => context.go('/ideas'),
        );
      case UpNextKind.nextMilestone:
        return _Directive(
          text: "Today's work is logged. Next up for $goalTitle: "
              '${milestone!.title}.',
          actionLabel: 'Open Focus',
          onTap: () => context.go('/focus'),
        );
      case UpNextKind.steady:
        return _Directive(
          text: state.goal?.isPaused ?? false
              ? '${state.goal!.title} is paused. Resume it whenever '
                  "you're ready — everything else still works."
              : "You're on pace today. Nothing urgent is waiting.",
          onTap: () => context.go('/focus'),
        );
    }
  }

  /// Quiet status lines under the hero — only for areas that need a glance.
  List<_Directive> _secondaryLines(BuildContext context) {
    final lines = <_Directive>[];
    final snapshot = state.money.snapshot;

    if (state.showsArea(DashboardArea.money) &&
        state.upNext != UpNextKind.moneyCritical) {
      if (!state.settings.hasIncome) {
        lines.add(_Directive(
          icon: Icons.account_balance_wallet_outlined,
          text: 'Set your income to see where the month stands.',
          onTap: () => context.go('/money'),
        ));
      } else if (snapshot.uncategorizedCount > 0) {
        lines.add(_Directive(
          icon: Icons.account_balance_wallet_outlined,
          text: '${snapshot.uncategorizedCount} uncategorized '
              'transaction${snapshot.uncategorizedCount == 1 ? '' : 's'} '
              'to sort.',
          onTap: () => context.go('/money'),
        ));
      }
    }

    if (state.showsArea(DashboardArea.time) &&
        state.upNext != UpNextKind.protectRecovery &&
        state.time.recoveryWeeklyTarget > 0 &&
        state.time.recoveryHoursThisWeek < 5) {
      lines.add(_Directive(
        icon: Icons.self_improvement,
        text: state.time.recoveryHoursThisWeek <= 0
            ? 'No downtime yet this week.'
            : 'Downtime is thin this week — protect a block tonight.',
        onTap: () => context.go('/time'),
      ));
    }

    if (state.showsArea(DashboardArea.ideas) &&
        state.upNext != UpNextKind.reviewIdeas &&
        state.ideasDueForReview > 0) {
      lines.add(_Directive(
        icon: Icons.lightbulb_outline,
        text: '${state.ideasDueForReview} '
            'idea${state.ideasDueForReview == 1 ? '' : 's'} waiting on a '
            'decision.',
        onTap: () => context.go('/ideas'),
      ));
    }

    return lines;
  }

  Widget _secondaryLine(BuildContext context, _Directive d) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: d.onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(d.icon, size: 15, color: theme.colorScheme.textTertiary),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                d.text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            if (d.onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: theme.colorScheme.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _Directive {
  const _Directive({
    required this.text,
    this.icon = Icons.circle,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onTap;
}

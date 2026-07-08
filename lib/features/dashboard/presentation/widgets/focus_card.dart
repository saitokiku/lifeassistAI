import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../kaizen/presentation/widgets/experiment_log_form.dart';
import '../../../kaizen/presentation/widgets/growth_metric_entry_form.dart';
import '../../application/dashboard_state.dart';

/// The hero of the Today screen: one directive that matters most right now,
/// with a direct action — the rest of the briefing sits quietly below it.
class FocusCard extends StatelessWidget {
  const FocusCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final directives = _directives(context);
    final hero = directives.first;
    final rest = directives.skip(1).toList();

    return AppCard(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S FOCUS",
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                ),
                onPressed: hero.onTap,
                child: Text(hero.actionLabel!),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          for (final d in rest) _secondaryLine(context, d),
        ],
      ),
    );
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

  /// The four command directives, most urgent first. Priority:
  /// money critical → kaizen front → recovery at zero → ideas due → steady.
  List<_Directive> _directives(BuildContext context) {
    final command = state.command;
    final snapshot = state.money.snapshot;

    final moneyCritical = snapshot.projectedSurplus < 0 ||
        snapshot.flags.any((f) => f.severity.name == 'critical');
    final recoveryZero = state.time.recoveryHoursThisWeek <= 0;
    final ideasDue = state.ideasDueForReview > 0;

    final kaizen = _Directive(
      icon: Icons.trending_up,
      text: command.kaizenAction,
      actionLabel: _kaizenActionLabel,
      onTap: () => _kaizenAction(context),
    );
    final money = _Directive(
      icon: Icons.account_balance_wallet_outlined,
      text: command.moneyConstraint,
      actionLabel: 'Review money',
      onTap: () => context.go('/money'),
    );
    final recovery = _Directive(
      icon: Icons.self_improvement,
      text: command.recoveryAction,
      actionLabel: 'Log recovery',
      onTap: () => context.go('/time'),
    );
    final ideas = _Directive(
      icon: Icons.filter_center_focus,
      text: command.antiDiffusionReminder,
      actionLabel: 'Review ideas',
      onTap: () => context.go('/ideas'),
    );

    // Steady-state hero keeps its text but drops the button.
    if (moneyCritical) return [money, kaizen, recovery, ideas];
    if (!state.kaizen.todayExperimentLogged ||
        state.time.kaizenHoursThisWeek <
            state.time.kaizenWeeklyTarget * 0.5 ||
        (state.kaizen.activeMetric != null &&
            state.kaizen.todayMetricValue == null)) {
      return [kaizen, money, recovery, ideas];
    }
    if (recoveryZero) return [recovery, kaizen, money, ideas];
    if (ideasDue) return [ideas, kaizen, money, recovery];
    return [kaizen.still(), money, recovery, ideas];
  }

  /// Label matching whichever branch generated the kaizen directive.
  String? get _kaizenActionLabel {
    if (!state.kaizen.todayExperimentLogged) return 'Log experiment';
    if (state.time.kaizenHoursThisWeek <
        state.time.kaizenWeeklyTarget * 0.5) {
      return 'Log time';
    }
    if (state.kaizen.activeMetric != null &&
        state.kaizen.todayMetricValue == null) {
      return 'Log value';
    }
    return null;
  }

  void _kaizenAction(BuildContext context) {
    if (!state.kaizen.todayExperimentLogged) {
      ExperimentLogForm.show(context);
      return;
    }
    if (state.time.kaizenHoursThisWeek <
        state.time.kaizenWeeklyTarget * 0.5) {
      context.go('/time');
      return;
    }
    final metric = state.kaizen.activeMetric;
    if (metric != null && state.kaizen.todayMetricValue == null) {
      GrowthMetricEntryForm.show(context, metric: metric);
      return;
    }
    context.go('/kaizen');
  }
}

class _Directive {
  const _Directive({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onTap;

  /// A copy without the primary action (steady-state hero).
  _Directive still() => _Directive(icon: icon, text: text, onTap: onTap);
}

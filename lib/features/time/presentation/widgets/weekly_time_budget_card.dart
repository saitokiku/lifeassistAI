import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/time_state.dart';
import '../../domain/time_category.dart';
import '../../domain/weekly_time_budget.dart';
import 'time_block_log_form.dart';
import 'time_budget_editor.dart';
import 'time_kind_icon.dart';

/// This week's actual vs target per category. Tapping a row opens the log
/// form with that category preselected — the fastest path to real hours.
class WeeklyTimeBudgetCard extends StatelessWidget {
  const WeeklyTimeBudgetCard({super.key, required this.state});

  final TimeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.progress.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No categories yet', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpace.xs),
            Text(
              'Set weekly targets so logged hours have somewhere to land.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                ),
                onPressed: () => TimeBudgetEditor.show(context),
                child: const Text('Create category'),
              ),
            ),
          ],
        ),
      );
    }

    final recoveryAtZero = state.recoveryWeeklyTarget > 0 &&
        state.recoveryHoursThisWeek <= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in state.progress) _BudgetRow(p: p, state: state),
          if (recoveryAtZero)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: Row(
                children: [
                  const Icon(Icons.self_improvement,
                      size: 14, color: AppColors.critical),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppCopy.recoveryExplainer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.critical,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.p, required this.state});

  final WeeklyTimeBudgetProgress p;
  final TimeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _barColor(p);
    final overBy = p.actualHours - p.targetHours;
    final showOver = p.isOverTarget && overBy >= 0.05;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.chip),
      onTap: () => TimeBlockLogForm.show(
        context,
        budgets: state.budgets,
        initialBudgetId: p.budget.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(p.kind.icon,
                    size: 16, color: theme.colorScheme.textTertiary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    p.budget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${Formatters.hours(p.actualHours)} / '
                  '${Formatters.hours(p.targetHours)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (showOver) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${Formatters.hours(overBy)} over',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            LabeledProgressBar(progress: p.progress, color: color, height: 5),
          ],
        ),
      ),
    );
  }

  /// Calm by default: brand color for main-goal time, neutral for the rest.
  /// Warning tints appear only when a category is meaningfully over plan —
  /// and never for goal time, where extra hours are the point.
  Color _barColor(WeeklyTimeBudgetProgress p) {
    if (p.kind == TimeCategoryKind.goal) return AppColors.primary;
    final overBy = p.actualHours - p.targetHours;
    if (p.isOverTarget && overBy >= 0.5) {
      return p.actualHours >= p.targetHours * 1.5
          ? AppColors.critical
          : AppColors.watch;
    }
    return AppColors.neutral;
  }
}

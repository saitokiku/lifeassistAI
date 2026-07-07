import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/time_state.dart';
import '../../domain/time_category.dart';
import '../../domain/weekly_time_budget.dart';

/// Actual vs target per category for this week.
class WeeklyTimeBudgetCard extends StatelessWidget {
  const WeeklyTimeBudgetCard({super.key, required this.state, this.onEdit});

  final TimeState state;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      title: 'Weekly budget · actual vs target',
      supportText: AppCopy.kaizenPriorityBlock,
      trailing: onEdit == null
          ? null
          : TextButton(onPressed: onEdit, child: const Text('Edit targets')),
      child: Column(
        children: [
          for (final p in state.progress)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LabeledProgressBar(
                progress: p.progress,
                color: _colorFor(p),
                leading: p.budget.name,
                trailing:
                    '${Formatters.hours(p.actualHours)} / ${Formatters.hours(p.targetHours)}'
                    '${p.isOverTarget ? ' · over' : ''}',
              ),
            ),
        ],
      ),
    );
  }

  Color _colorFor(WeeklyTimeBudgetProgress p) {
    if (p.kind == TimeCategoryKind.kaizen) return AppColors.primary;
    if (p.kind.countsAsRecovery) {
      return p.actualHours <= 0 ? AppColors.critical : AppColors.aligned;
    }
    if (p.isOverTarget) return AppColors.watch;
    return AppColors.neutral;
  }
}

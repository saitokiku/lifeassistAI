import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/identity_controller.dart';
import '../../domain/goal.dart';
import 'goals_editor.dart';

/// Goals with progress bars and edit/delete.
class GoalProgressList extends ConsumerWidget {
  const GoalProgressList({super.key, required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (goals.isEmpty) {
      return EmptyState(
        icon: Icons.flag_outlined,
        title: 'No goals yet',
        message: 'Set the few targets that matter.',
        actionLabel: 'Add goal',
        onAction: () => GoalsEditor.show(context),
      );
    }

    return Column(
      children: [
        for (final goal in goals)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledProgressBar(
                          progress: goal.progress,
                          color: AppColors.primary,
                          leading: goal.title,
                          trailing:
                              '${Formatters.number(goal.currentValue)} / ${Formatters.number(goal.targetValue)}'
                              '${goal.metricName == null ? '' : ' ${goal.metricName}'}',
                        ),
                        if (goal.targetDate?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'by ${goal.targetDate}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await GoalsEditor.show(context, goal: goal);
                      } else if (value == 'delete') {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Delete goal?',
                          message: 'Removes "${goal.title}".',
                        );
                        if (confirmed) {
                          await ref
                              .read(identityControllerProvider)
                              .deleteGoal(goal.id);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

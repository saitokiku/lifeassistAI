import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/identity_controller.dart';
import '../../domain/goal.dart';
import 'goals_editor.dart';
import 'quick_update_sheet.dart';

/// Goals as tappable progress rows: tap the bar to log progress,
/// menu or swipe for everything else. The percent label tells the truth —
/// overshoot reads 112%, not a flat 100%.
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
        actionLabel: 'New goal',
        onAction: () => GoalsEditor.show(context),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < goals.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.cardGap),
          _GoalCard(goal: goals[i]),
        ],
      ],
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overshoot =
        goal.targetValue > 0 && goal.currentValue >= goal.targetValue;
    final percentLabel = goal.targetValue <= 0
        ? '—'
        : Formatters.percent(goal.currentValue / goal.targetValue);

    return Dismissible(
      key: ValueKey('goal-${goal.id}'),
      direction: DismissDirection.endToStart,
      background: const _SwipeDeleteBackground(),
      onDismissed: (_) => _deleteWithUndo(context, ref),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.cardPadding,
          AppSpace.tilePadding,
          AppSpace.sm,
          AppSpace.tilePadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    _metaLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  InkWell(
                    onTap: () => _quickUpdate(context, ref),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpace.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: LabeledProgressBar(
                              progress: goal.progress,
                              color: overshoot
                                  ? AppColors.aligned
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Text(
                            percentLabel,
                            style: theme.textTheme.numberBody.copyWith(
                              fontSize: 13,
                              color: overshoot
                                  ? AppColors.aligned
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: theme.colorScheme.textTertiary,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  GoalsEditor.show(context, goal: goal);
                } else if (value == 'delete') {
                  _deleteWithUndo(context, ref);
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
    );
  }

  String get _metaLine {
    final unit = goal.metricName == null ? '' : ' ${goal.metricName}';
    var line =
        '${Formatters.number(goal.currentValue)} of ${Formatters.number(goal.targetValue)}$unit';
    final dateKey = goal.targetDate;
    if (dateKey != null && dateKey.isNotEmpty) {
      line += ' · by ${Formatters.fullDate(AppDateUtils.parseDateKey(dateKey))}';
    }
    return line;
  }

  Future<void> _quickUpdate(BuildContext context, WidgetRef ref) {
    final controller = ref.read(identityControllerProvider);
    final unit = goal.metricName == null ? '' : ' ${goal.metricName}';
    return QuickUpdateSheet.show(
      context,
      title: goal.title,
      subtitle: 'Aiming at ${Formatters.number(goal.targetValue)}$unit.',
      label: 'Current',
      initialValue: goal.currentValue,
      validator: (v) => Validators.number(v, label: 'Current'),
      onSave: (value) =>
          controller.updateGoal(goal.copyWith(currentValue: value)),
    );
  }

  void _deleteWithUndo(BuildContext context, WidgetRef ref) {
    final controller = ref.read(identityControllerProvider);
    final removed = goal;
    Haptics.light();
    controller.deleteGoal(removed.id);
    showUndoSnack(context, 'Goal deleted.', onUndo: () {
      controller.createGoal(
        title: removed.title,
        description: removed.description,
        metricName: removed.metricName,
        currentValue: removed.currentValue,
        targetValue: removed.targetValue,
        targetDate: removed.targetDate == null || removed.targetDate!.isEmpty
            ? null
            : AppDateUtils.parseDateKey(removed.targetDate!),
      );
    });
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.critical.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        size: 22,
        color: AppColors.critical,
      ),
    );
  }
}

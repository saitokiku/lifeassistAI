import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/check_ring.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../../../shared/widgets/quick_update_sheet.dart';
import '../../application/focus_controller.dart';
import '../../domain/milestone.dart';
import 'milestone_editor.dart';

/// Milestones as one grouped list: check off a step, tap to edit, menu for
/// the rest. Measurable milestones show a progress bar that opens a quick
/// value update. Done milestones sink to the bottom, dimmed.
class MilestoneList extends ConsumerWidget {
  const MilestoneList({super.key, required this.milestones, this.today});

  final List<Goal> milestones;
  final DateTime? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        children: [
          for (final (i, m) in milestones.indexed) ...[
            if (i > 0)
              const Divider(height: 1, indent: AppSpace.lg + 26 + AppSpace.md),
            _MilestoneRow(milestone: m, today: today),
          ],
        ],
      ),
    );
  }
}

class _MilestoneRow extends ConsumerWidget {
  const _MilestoneRow({required this.milestone, this.today});

  final Goal milestone;
  final DateTime? today;

  Future<void> _toggleDone(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(focusControllerProvider);
    final nowDone = !milestone.isDone;
    await controller.setMilestoneDone(milestone.id, nowDone);
    if (nowDone) {
      Haptics.medium();
      if (context.mounted) {
        showUndoSnack(
          context,
          'Milestone done. Nice.',
          onUndo: () => controller.setMilestoneDone(milestone.id, false),
        );
      }
    } else {
      Haptics.light();
    }
  }

  Future<void> _quickUpdate(BuildContext context, WidgetRef ref) {
    final controller = ref.read(focusControllerProvider);
    final unit =
        milestone.metricName == null ? '' : ' ${milestone.metricName}';
    return QuickUpdateSheet.show(
      context,
      title: milestone.title,
      subtitle: 'Aiming at ${Formatters.number(milestone.targetValue)}$unit.',
      label: 'Current',
      initialValue: milestone.currentValue,
      validator: (v) => Validators.number(v, label: 'Current'),
      onSave: (value) =>
          controller.updateMilestone(milestone.copyWith(currentValue: value)),
    );
  }

  void _deleteWithUndo(BuildContext context, WidgetRef ref) {
    final controller = ref.read(focusControllerProvider);
    final removed = milestone;
    Haptics.light();
    controller.deleteMilestone(removed.id);
    showUndoSnack(context, 'Milestone deleted.', onUndo: () {
      controller.createMilestone(
        title: removed.title,
        description: removed.description,
        metricName: removed.metricName,
        currentValue: removed.currentValue,
        targetValue: removed.targetValue,
        targetDate: removed.targetDateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = milestone.isDone;

    return InkWell(
      onTap: () => MilestoneEditor.show(context, milestone: milestone),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.xs, AppSpace.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: done
                  ? '${milestone.title}, done. Tap to reopen.'
                  : '${milestone.title}, not done. Tap to mark done.',
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleDone(context, ref),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CheckRing(checked: done, size: 22),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: done ? scheme.onSurfaceVariant : null,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (_metaLine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _metaLine!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.textTertiary,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ],
                  if (milestone.isMeasurable && !done) ...[
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
                                progress: milestone.progress,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpace.md),
                            Text(
                              Formatters.percent(milestone.progress),
                              style: theme.textTheme.numberBody.copyWith(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                size: 20,
                color: scheme.textTertiary,
              ),
              tooltip: 'More',
              onSelected: (value) {
                if (value == 'edit') {
                  MilestoneEditor.show(context, milestone: milestone);
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

  String? get _metaLine {
    final parts = <String>[];
    if (milestone.isMeasurable) {
      final unit =
          milestone.metricName == null ? '' : ' ${milestone.metricName}';
      parts.add('${Formatters.number(milestone.currentValue)} of '
          '${Formatters.number(milestone.targetValue)}$unit');
    }
    final date = milestone.targetDateTime;
    if (date != null) parts.add('by ${Formatters.fullDate(date)}');
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

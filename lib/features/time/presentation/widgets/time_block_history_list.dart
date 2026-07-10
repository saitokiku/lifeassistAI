import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/time_controller.dart';
import '../../domain/time_category.dart';
import 'time_block_log_form.dart';
import 'time_kind_icon.dart';

/// Recent entries grouped by day. Tap to edit; swipe away to delete with
/// undo — the entry is cheap to recreate, so no blocking confirm.
class TimeBlockHistoryList extends ConsumerWidget {
  const TimeBlockHistoryList({
    super.key,
    required this.blocks,
    required this.budgets,
    this.now,
  });

  final List<TimeBlock> blocks;
  final List<TimeBudget> budgets;

  /// Anchor for Today/Yesterday labels; falls back to the wall clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (blocks.isEmpty) {
      return EmptyState(
        icon: Icons.timer_outlined,
        title: 'No hours logged yet',
        message: 'Everything here feeds the scoreboard. Log the first block.',
        actionLabel: 'Log time',
        onAction: () => TimeBlockLogForm.show(context, budgets: budgets),
      );
    }

    final budgetById = {for (final b in budgets) b.id: b};
    final today = AppDateUtils.dateOnly(now ?? DateTime.now());

    // Blocks arrive date-desc; group consecutive runs of the same day.
    final groups = <(String, List<TimeBlock>)>[];
    for (final block in blocks) {
      final label = _dayLabel(block.date, today);
      if (groups.isEmpty || groups.last.$1 != label) {
        groups.add((label, [block]));
      } else {
        groups.last.$2.add(block);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, group) in groups.indexed) ...[
          Padding(
            padding: EdgeInsets.only(
              top: i == 0 ? 0 : AppSpace.lg,
              bottom: AppSpace.sm,
            ),
            child: Text(
              group.$1,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.textTertiary,
              ),
            ),
          ),
          for (final block in group.$2)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _BlockRow(
                block: block,
                budget: budgetById[block.budgetId],
                budgets: budgets,
              ),
            ),
        ],
      ],
    );
  }

  String _dayLabel(String dateKey, DateTime today) {
    final date = AppDateUtils.parseDateKey(dateKey);
    if (AppDateUtils.isSameDay(date, today)) return 'Today';
    if (AppDateUtils.isSameDay(date, today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return date.year == today.year
        ? Formatters.shortDate(date)
        : Formatters.fullDate(date);
  }
}

class _BlockRow extends ConsumerWidget {
  const _BlockRow({
    required this.block,
    required this.budget,
    required this.budgets,
  });

  final TimeBlock block;
  final TimeBudget? budget;
  final List<TimeBudget> budgets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final kind = budget == null ? null : TimeCategoryKind.parse(budget!.kind);
    final note = block.note;

    return Dismissible(
      key: ValueKey('time-block-${block.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.xl),
        decoration: BoxDecoration(
          color: AppColors.critical.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.critical),
      ),
      onDismissed: (_) => _delete(context, ref),
      child: AppCard(
        onTap: () => TimeBlockLogForm.show(
          context,
          budgets: budgets,
          block: block,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            Icon(
              kind?.icon ?? Icons.category_outlined,
              size: 18,
              color: theme.colorScheme.textTertiary,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget?.name ?? 'Deleted category',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              Formatters.hours(block.hours),
              style: theme.textTheme.numberBody,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(timeControllerProvider);
    // Capture everything needed to bring the entry back.
    final budgetId = block.budgetId;
    final date = AppDateUtils.parseDateKey(block.date);
    final hours = block.hours;
    final note = block.note;
    try {
      await controller.deleteBlock(block.id);
    } catch (_) {
      if (context.mounted) {
        showErrorSnack(context, "That didn't delete. Try again.");
      }
      return;
    }
    Haptics.medium();
    if (!context.mounted) return;
    showUndoSnack(
      context,
      '${Formatters.hours(hours)} removed.',
      onUndo: () => controller.logBlock(
        budgetId: budgetId,
        date: date,
        hours: hours,
        note: note,
      ),
    );
  }
}

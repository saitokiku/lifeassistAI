import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/focus_controller.dart';
import '../../domain/daily_action.dart';
import 'action_log_form.dart';
import 'relative_date.dart';

/// Daily action history: outcome filter chips, then one row per day.
/// Tap edits; swipe deletes with undo. Filters get their own empty copy.
class ActionHistoryList extends ConsumerStatefulWidget {
  const ActionHistoryList({
    super.key,
    required this.actions,
    this.today,
  });

  final List<DailyExperiment> actions;

  /// The app's ticking "today"; falls back to the device clock.
  final DateTime? today;

  @override
  ConsumerState<ActionHistoryList> createState() => _ActionHistoryListState();
}

class _ActionHistoryListState extends ConsumerState<ActionHistoryList> {
  ActionVerdict? _filter;

  static const _filterOrder = [
    ActionVerdict.worked,
    ActionVerdict.adjust,
    ActionVerdict.didntWork,
  ];

  void _setFilter(ActionVerdict? value) {
    Haptics.select();
    setState(() => _filter = value);
  }

  Future<void> _edit(DailyExperiment action) =>
      ActionLogForm.show(context, action: action);

  /// Delete with a working undo: re-logs the captured row via logAction.
  Future<void> _delete(DailyExperiment action) async {
    final controller = ref.read(focusControllerProvider);
    final date = AppDateUtils.parseDateKey(action.date);
    final hypothesis = action.hypothesis;
    final actionTaken = action.actionTaken;
    final result = action.result;
    final verdict = action.verdict;
    final notes = action.notes;

    await controller.deleteAction(action.id);
    Haptics.light();
    if (!mounted) return;
    showUndoSnack(
      context,
      'Entry deleted.',
      onUndo: () => controller.logAction(
        date: date,
        hypothesis: hypothesis,
        actionTaken: actionTaken,
        result: result,
        verdict: verdict,
        notes: notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.today ??
        ref.watch(focusStateProvider)?.today ??
        AppDateUtils.dateOnly(DateTime.now());

    final filtered = _filter == null
        ? widget.actions
        : [
            for (final a in widget.actions)
              if (a.verdictEnum == _filter) a,
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _filter == null,
              onSelected: (_) => _setFilter(null),
            ),
            for (final v in _filterOrder)
              FilterChip(
                label: Text(v.label),
                selected: _filter == v,
                onSelected: (_) => _setFilter(v),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        if (widget.actions.isEmpty)
          const EmptyState(
            icon: Icons.directions_walk,
            title: 'Nothing logged yet',
            message: 'Each day, take one small step toward your goal and '
                'note how it went. The log becomes your map of what works.',
          )
        else if (filtered.isEmpty)
          EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: 'Nothing matches this filter.',
            actionLabel: 'Clear filter',
            onAction: () => _setFilter(null),
          )
        else
          for (final action in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _ActionRow(
                action: action,
                today: today,
                onEdit: () => _edit(action),
                onDelete: () => _delete(action),
              ),
            ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.today,
    required this.onEdit,
    required this.onDelete,
  });

  final DailyExperiment action;
  final DateTime today;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final verdict = action.verdictEnum;
    final when = relativeDayLabel(
      AppDateUtils.parseDateKey(action.date),
      today,
    );
    // Older entries may only carry the hypothesis field.
    final headline =
        action.actionTaken.isNotEmpty ? action.actionTaken : action.hypothesis;

    return Dismissible(
      key: ValueKey('action-${action.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.xl),
        decoration: BoxDecoration(
          color: AppColors.critical.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.critical,
        ),
      ),
      confirmDismiss: (_) async {
        await onDelete();
        return true;
      },
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.xs, AppSpace.md,
        ),
        onTap: onEdit,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: verdict.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${verdict.label} · $when',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
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
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
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
}

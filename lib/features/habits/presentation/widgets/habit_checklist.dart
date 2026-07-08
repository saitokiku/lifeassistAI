import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/check_ring.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/habits_controller.dart';
import '../../application/habits_state.dart';
import '../../domain/habit.dart';
import 'habit_editor.dart';
import 'habit_value_sheet.dart';

const _saveError = "That didn't save. Try again.";

enum _RowAction { edit, archive, delete }

/// The unified habit list: one row per habit combining today's check-in,
/// this week's dots, the streak, and the edit/archive/delete menu.
class HabitChecklist extends ConsumerWidget {
  const HabitChecklist({super.key, required this.state});

  final HabitsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final (index, view) in state.habits.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  index == state.habits.length - 1 ? 0 : AppSpace.cardGap,
            ),
            child: _HabitRow(
              view: view,
              onCheck: () => _toggleToday(context, ref, view),
              onTap: () => _rowTap(context, ref, view),
              onAction: (action) => _handleAction(context, ref, view, action),
            ),
          ),
      ],
    );
  }

  /// Ring tap: toggles today's log. Unchecking is always undoable.
  Future<void> _toggleToday(
    BuildContext context,
    WidgetRef ref,
    HabitView view,
  ) async {
    final controller = ref.read(habitsControllerProvider);

    if (view.doneToday) {
      // Capture the entry before it goes — undo must restore value and note.
      final log = view.todayLog!;
      try {
        await controller.unlogHabit(habitId: view.habit.id, date: view.today);
      } catch (_) {
        if (context.mounted) showErrorSnack(context, _saveError);
        return;
      }
      if (!context.mounted) return;
      showUndoSnack(
        context,
        '${view.habit.name} unchecked.',
        onUndo: () => controller.logHabit(
          habitId: view.habit.id,
          date: view.today,
          value: log.value,
          note: log.note,
        ),
      );
      return;
    }

    if (HabitType.parse(view.habit.type) == HabitType.boolean) {
      final completesBoard = _completesBoard(view);
      try {
        await controller.logHabit(
          habitId: view.habit.id,
          date: view.today,
          value: 1,
        );
      } catch (_) {
        if (context.mounted) showErrorSnack(context, _saveError);
        return;
      }
      if (completesBoard && context.mounted) _celebrate(context);
      return;
    }

    await _logValue(context, ref, view);
  }

  /// Row tap: booleans toggle; value habits open the value sheet —
  /// prefilled with today's entry when logged, so editing never destroys.
  Future<void> _rowTap(
    BuildContext context,
    WidgetRef ref,
    HabitView view,
  ) async {
    if (HabitType.parse(view.habit.type) == HabitType.boolean) {
      Haptics.light();
      await _toggleToday(context, ref, view);
    } else {
      await _logValue(context, ref, view);
    }
  }

  Future<void> _logValue(
    BuildContext context,
    WidgetRef ref,
    HabitView view,
  ) async {
    final completesBoard = _completesBoard(view);
    final logged = await HabitValueSheet.show(context, view: view);
    if (logged && completesBoard && context.mounted) _celebrate(context);
  }

  /// True when [view] is the only habit still unlogged today.
  bool _completesBoard(HabitView view) =>
      !view.doneToday &&
      state.habits.every((h) => h.habit.id == view.habit.id || h.doneToday);

  void _celebrate(BuildContext context) {
    Haptics.medium();
    showSuccessSnack(context, "That's the board cleared. Small win logged.");
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    HabitView view,
    _RowAction action,
  ) async {
    switch (action) {
      case _RowAction.edit:
        await HabitEditor.show(context, habit: view.habit);
      case _RowAction.archive:
        await _archive(context, ref, view);
      case _RowAction.delete:
        await _delete(context, ref, view);
    }
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    HabitView view,
  ) async {
    final controller = ref.read(habitsControllerProvider);
    try {
      await controller.updateHabit(view.habit.copyWith(isArchived: true));
    } catch (_) {
      if (context.mounted) showErrorSnack(context, _saveError);
      return;
    }
    Haptics.medium();
    if (!context.mounted) return;
    showUndoSnack(
      context,
      '${view.habit.name} archived. History kept.',
      onUndo: () =>
          controller.updateHabit(view.habit.copyWith(isArchived: false)),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    HabitView view,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete forever?',
      message:
          'This erases "${view.habit.name}" and every log it ever recorded — '
          'streaks included. Archiving keeps the history.',
      confirmLabel: 'Delete forever',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(habitsControllerProvider).deleteHabit(view.habit.id);
    } catch (_) {
      if (context.mounted) showErrorSnack(context, _saveError);
    }
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.view,
    required this.onCheck,
    required this.onTap,
    required this.onAction,
  });

  final HabitView view;
  final VoidCallback onCheck;
  final VoidCallback onTap;
  final ValueChanged<_RowAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valueLabel = _todayValueLabel();

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.sm,
        AppSpace.sm,
        AppSpace.xs,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          CheckRing(checked: view.doneToday, onTap: onCheck),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  view.habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if (valueLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    valueLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (view.streak > 0) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 13,
                      color: AppColors.watch,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${view.streak}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],
              _WeekDots(view: view),
            ],
          ),
          PopupMenuButton<_RowAction>(
            tooltip: 'Habit actions',
            icon: Icon(
              Icons.more_horiz,
              size: 20,
              color: scheme.textTertiary,
            ),
            onSelected: onAction,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _RowAction.edit,
                child: Text('Edit'),
              ),
              const PopupMenuItem(
                value: _RowAction.archive,
                child: Text('Archive'),
              ),
              PopupMenuItem(
                value: _RowAction.delete,
                child: Text(
                  'Delete forever',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.critical),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "20 min" — trimmed number, no dangling space, value habits only.
  String? _todayValueLabel() {
    final log = view.todayLog;
    final type = HabitType.parse(view.habit.type);
    if (log == null || type == HabitType.boolean) return null;
    final unit = type == HabitType.duration
        ? 'min'
        : (view.habit.unit?.trim() ?? '');
    final value = Formatters.number(log.value);
    return unit.isEmpty ? value : '$value $unit';
  }
}

/// Mon–Sun dots for the current week: filled when logged, today outlined
/// while still open. Neutral by design — no seven-day quota implied.
class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.view});

  final HabitView view;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final keys = AppDateUtils.weekDateKeys(view.today);
    final todayKey = AppDateUtils.dateKey(view.today);
    final logged = view.loggedDays;

    return Semantics(
      label:
          '${view.weeklyCount} day${view.weeklyCount == 1 ? '' : 's'} this week',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, key) in keys.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpace.xs),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: logged.contains(key)
                    ? AppColors.primary
                    : key == todayKey
                        ? Colors.transparent
                        : scheme.outline,
                border: key == todayKey && !logged.contains(key)
                    ? Border.all(color: scheme.textTertiary, width: 1.3)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/check_ring.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../habits/application/habits_controller.dart';
import '../../../habits/application/habits_state.dart';
import '../../../habits/domain/habit.dart';
import '../../../settings/domain/user_settings.dart';
import '../../../focus/presentation/widgets/action_log_form.dart';
import '../../../focus/presentation/widgets/growth_metric_entry_form.dart';
import '../../application/dashboard_state.dart';

/// One-tap daily check-ins: the goal step, the tracked measure, habits.
/// Boolean habits toggle instantly; value habits open a two-field sheet.
/// Unchecking is undoable — never silently destructive.
/// Renders nothing when there is nothing to check in on.
class CheckInStrip extends ConsumerWidget {
  const CheckInStrip({super.key, required this.state});

  final DashboardState state;

  /// Whether any chip would render (the screen hides the header otherwise).
  static bool hasChips(DashboardState state, {required bool anyHabits}) =>
      state.goalActive || (state.showsArea(DashboardArea.habits) && anyHabits);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsStateProvider);
    final chips = <Widget>[];

    // The daily step toward the goal leads.
    if (state.goalActive) {
      final action = state.focus.todayAction;
      chips.add(_CheckChip(
        label: "Today's step",
        checked: action != null,
        onTap: () => ActionLogForm.show(context, action: action),
      ));

      // The tracked measure's value.
      final metric = state.focus.activeMetric;
      if (metric != null) {
        final logged = state.focus.todayMetricValue != null;
        chips.add(_CheckChip(
          label: logged
              ? '${metric.name} · ${Formatters.number(state.focus.todayMetricValue!)}'
              : metric.name,
          checked: logged,
          onTap: () => GrowthMetricEntryForm.show(context, metric: metric),
        ));
      }
    }

    if (state.showsArea(DashboardArea.habits)) {
      for (final h in habits?.habits ?? const <HabitView>[]) {
        chips.add(_CheckChip(
          label: _habitLabel(h),
          checked: h.doneToday,
          onTap: () => _toggleHabit(context, ref, h),
        ));
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (i, chip) in chips.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpace.sm),
            chip,
          ],
        ],
      ),
    );
  }

  String _habitLabel(HabitView h) {
    final log = h.todayLog;
    final type = HabitType.parse(h.habit.type);
    if (log == null || type == HabitType.boolean) return h.habit.name;
    final unit = type == HabitType.duration ? 'min' : (h.habit.unit ?? '');
    final value = Formatters.number(log.value);
    return '${h.habit.name} · $value${unit.isEmpty ? '' : ' $unit'}';
  }

  Future<void> _toggleHabit(
    BuildContext context,
    WidgetRef ref,
    HabitView h,
  ) async {
    final controller = ref.read(habitsControllerProvider);
    final today = h.today;

    if (h.doneToday) {
      // Unchecking preserves the entry via undo — never silent data loss.
      final log = h.todayLog!;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await controller.unlogHabit(habitId: h.habit.id, date: today);
      } catch (_) {
        if (context.mounted) {
          showErrorSnack(context, "That didn't save. Try again.");
        }
        return;
      }
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      showUndoSnack(
        context,
        '${h.habit.name} unchecked.',
        onUndo: () => controller.logHabit(
          habitId: h.habit.id,
          date: today,
          value: log.value,
          note: log.note,
        ),
      );
      return;
    }

    final type = HabitType.parse(h.habit.type);
    if (type == HabitType.boolean) {
      try {
        await controller.logHabit(habitId: h.habit.id, date: today, value: 1);
      } catch (_) {
        if (context.mounted) {
          showErrorSnack(context, "That didn't save. Try again.");
        }
      }
      return;
    }

    if (!context.mounted) return;
    await _askValue(context, ref, h, type);
  }

  /// Small value sheet for numeric/duration habits, with the last logged
  /// value as a one-tap default.
  Future<void> _askValue(
    BuildContext context,
    WidgetRef ref,
    HabitView h,
    HabitType type,
  ) async {
    final controller = ref.read(habitsControllerProvider);
    final lastValue = h.logs.isNotEmpty ? h.logs.first.value : null;
    final valueController = TextEditingController(
      text: lastValue != null ? Formatters.number(lastValue) : '',
    );
    final formKey = GlobalKey<FormState>();
    final unit = type == HabitType.duration ? 'min' : h.habit.unit;

    await showAppSheet<void>(
      context,
      builder: (sheetContext) => AppSheet(
        title: h.habit.name,
        subtitle: lastValue != null
            ? 'Last time: ${Formatters.number(lastValue)}${unit == null ? '' : ' $unit'}'
            : null,
        footer: AppSheetButton(
          label: 'Log it',
          onPressed: () async {
            if (!(formKey.currentState?.validate() ?? false)) return;
            final navigator = Navigator.of(sheetContext);
            try {
              await controller.logHabit(
                habitId: h.habit.id,
                date: h.today,
                value: Validators.parseNumber(valueController.text),
              );
            } catch (_) {
              if (sheetContext.mounted) {
                showErrorSnack(sheetContext, "That didn't save. Try again.");
              }
              return;
            }
            Haptics.light();
            navigator.pop();
          },
        ),
        children: [
          Form(
            key: formKey,
            child: AppNumberField(
              label: 'Today',
              controller: valueController,
              suffixText: unit,
            ),
          ),
        ],
      ),
    );
    valueController.dispose();
  }
}

class _CheckChip extends StatelessWidget {
  const _CheckChip({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: checked
          ? Color.alphaBlend(scheme.primaryTint, scheme.elevated)
          : scheme.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(
          color: checked ? scheme.primaryTintBorder : scheme.outlineFaint,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Haptics.light();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, AppSpace.lg, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IgnorePointer(
                child: CheckRing(checked: checked, size: 22),
              ),
              const SizedBox(width: 2),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: checked ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

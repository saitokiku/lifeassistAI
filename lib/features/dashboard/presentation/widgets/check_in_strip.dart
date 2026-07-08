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
import '../../../kaizen/presentation/widgets/experiment_log_form.dart';
import '../../../kaizen/presentation/widgets/growth_metric_entry_form.dart';
import '../../application/dashboard_state.dart';

/// One-tap daily check-ins: habits, the experiment, the metric value.
/// Boolean habits toggle instantly; value habits open a two-field sheet.
/// Unchecking is undoable — never silently destructive.
class CheckInStrip extends ConsumerWidget {
  const CheckInStrip({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsStateProvider);
    final chips = <Widget>[];

    // The experiment — the day's core ritual leads.
    final experiment = state.kaizen.todayExperiment;
    chips.add(_CheckChip(
      label: 'Experiment',
      checked: experiment != null,
      onTap: () => ExperimentLogForm.show(context, experiment: experiment),
    ));

    // The active metric value.
    final metric = state.kaizen.activeMetric;
    if (metric != null) {
      final logged = state.kaizen.todayMetricValue != null;
      chips.add(_CheckChip(
        label: logged
            ? '${metric.name} · ${Formatters.number(state.kaizen.todayMetricValue!)}'
            : metric.name,
        checked: logged,
        onTap: () => GrowthMetricEntryForm.show(context, metric: metric),
      ));
    }

    for (final h in habits?.habits ?? const <HabitView>[]) {
      chips.add(_CheckChip(
        label: _habitLabel(h),
        checked: h.doneToday,
        onTap: () => _toggleHabit(context, ref, h),
      ));
    }

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
    final unit =
        type == HabitType.duration ? 'min' : (h.habit.unit ?? '');
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
      await controller.unlogHabit(habitId: h.habit.id, date: today);
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
      await controller.logHabit(habitId: h.habit.id, date: today, value: 1);
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
            await controller.logHabit(
              habitId: h.habit.id,
              date: h.today,
              value: Validators.parseNumber(valueController.text),
            );
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
                  color: checked
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

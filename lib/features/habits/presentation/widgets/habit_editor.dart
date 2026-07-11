import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/health/health_habit_sync.dart';
import '../../../../core/health/health_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../core/utils/weekdays.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/weekday_picker.dart';
import '../../application/habits_controller.dart';
import '../../domain/habit.dart';

/// Create or edit a habit.
class HabitEditor extends ConsumerStatefulWidget {
  const HabitEditor({super.key, this.habit});

  final Habit? habit;

  static Future<void> show(BuildContext context, {Habit? habit}) =>
      showAppSheet<void>(
        context,
        builder: (_) => HabitEditor(habit: habit),
      );

  @override
  ConsumerState<HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends ConsumerState<HabitEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.habit?.name ?? '');
  late final _unit = TextEditingController(text: widget.habit?.unit ?? '');
  late HabitType _type = widget.habit == null
      ? HabitType.boolean
      : HabitType.parse(widget.habit!.type);
  late int _weekdays = widget.habit?.weekdays ?? WeekdayMask.all;
  late TimeOfDay? _reminder = widget.habit?.reminderHour == null
      ? null
      : TimeOfDay(
          hour: widget.habit!.reminderHour!,
          minute: widget.habit!.reminderMinute ?? 0,
        );
  late String? _healthMetric = widget.habit?.healthMetric;
  late final _healthTarget = TextEditingController(
      text: widget.habit?.healthTarget == null
          ? ''
          : Formatters.number(widget.habit!.healthTarget!, maxDecimals: 1));

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _healthTarget.dispose();
    super.dispose();
  }

  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      Haptics.select();
      setState(() => _reminder = picked);
    }
  }

  bool get _typeChanged =>
      widget.habit != null && _type.name != widget.habit!.type;

  String _typeLabel(HabitType type) => switch (type) {
        HabitType.boolean => 'Done / not done',
        HabitType.numeric => 'Number',
        HabitType.duration => 'Minutes',
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(habitsControllerProvider);
    final navigator = Navigator.of(context);
    final unit = _unit.text.trim().isEmpty ? null : _unit.text.trim();
    // A boolean habit needs a threshold to auto-check against; without
    // one the mapping is meaningless, so it isn't saved.
    final target = double.tryParse(_healthTarget.text.trim());
    final metric = _healthMetric == null ||
            (_type == HabitType.boolean && (target == null || target <= 0))
        ? null
        : _healthMetric;
    try {
      if (widget.habit == null) {
        await controller.createHabit(
          name: _name.text.trim(),
          type: _type.name,
          unit: unit,
          weekdays: _weekdays,
          reminderHour: _reminder?.hour,
          reminderMinute: _reminder?.minute,
          healthMetric: metric,
          healthTarget: metric == null ? null : target,
        );
      } else {
        await controller.updateHabit(widget.habit!.copyWith(
          name: _name.text.trim(),
          type: _type.name,
          unit: Value(unit),
          weekdays: _weekdays,
          reminderHour: Value(_reminder?.hour),
          reminderMinute: Value(_reminder?.minute),
          healthMetric: Value(metric),
          healthTarget: Value(metric == null ? null : target),
        ));
      }
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
      return;
    }
    Haptics.medium();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedFg = theme.brightness == Brightness.dark
        ? AppColors.primaryBright
        : AppColors.primaryDim;

    // Warn before a type change reinterprets existing history.
    final hasLogs = widget.habit != null &&
        (ref
                .watch(habitLogsProvider)
                .valueOrNull
                ?.any((l) => l.habitId == widget.habit!.id) ??
            false);

    return AppSheet(
      title: widget.habit == null ? 'New habit' : 'Edit habit',
      footer: AppSheetButton(
        label: widget.habit == null ? 'Create habit' : 'Save',
        onPressed: _save,
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Name',
                controller: _name,
                autofocus: widget.habit == null,
                validator: (v) => Validators.required(v, label: 'Name'),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                'Type',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final type in HabitType.values)
                    ChoiceChip(
                      label: Text(_typeLabel(type)),
                      selected: _type == type,
                      showCheckmark: false,
                      selectedColor: AppColors.primary.withValues(alpha: 0.16),
                      side: BorderSide(
                        color: _type == type
                            ? scheme.primaryTintBorder
                            : scheme.outlineFaint,
                      ),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        color: _type == type
                            ? selectedFg
                            : scheme.onSurfaceVariant,
                      ),
                      onSelected: (selected) {
                        if (!selected) return;
                        Haptics.select();
                        setState(() => _type = type);
                      },
                    ),
                ],
              ),
              if (_type == HabitType.numeric) ...[
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  label: 'Unit',
                  hint: 'reps, pages, km…',
                  controller: _unit,
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              Text(
                'Days',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  ChoiceChip(
                    label: const Text('Every day'),
                    selected: _weekdays == WeekdayMask.all,
                    showCheckmark: false,
                    onSelected: (_) {
                      Haptics.select();
                      setState(() => _weekdays = WeekdayMask.all);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Some days'),
                    selected: _weekdays != WeekdayMask.all,
                    showCheckmark: false,
                    onSelected: (_) {
                      Haptics.select();
                      setState(() {
                        if (_weekdays == WeekdayMask.all) {
                          _weekdays = WeekdayMask.weekdaysOnly;
                        }
                      });
                    },
                  ),
                ],
              ),
              if (_weekdays != WeekdayMask.all) ...[
                const SizedBox(height: AppSpace.md),
                WeekdayPicker(
                  mask: _weekdays,
                  onChanged: (mask) => setState(() => _weekdays = mask),
                ),
                const SizedBox(height: 6),
                Text(
                  'Off days don\'t nag and don\'t break the streak.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.textTertiary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              Text(
                'Reminder',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  ChoiceChip(
                    label: const Text('No reminder'),
                    selected: _reminder == null,
                    showCheckmark: false,
                    onSelected: (_) {
                      Haptics.select();
                      setState(() => _reminder = null);
                    },
                  ),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    label: Text(
                      _reminder == null
                          ? 'Pick a time'
                          : Formatters.timeOfDay(
                              _reminder!.hour, _reminder!.minute),
                    ),
                    selected: _reminder != null,
                    showCheckmark: false,
                    onSelected: (_) => _pickReminder(),
                  ),
                ],
              ),
              if (ref.watch(healthAvailabilityProvider).valueOrNull ==
                  HealthAvailability.ready) ...[
                const SizedBox(height: AppSpace.lg),
                Text(
                  'From Apple Health',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('Off'),
                      selected: _healthMetric == null,
                      showCheckmark: false,
                      onSelected: (_) {
                        Haptics.select();
                        setState(() => _healthMetric = null);
                      },
                    ),
                    for (final entry in HealthHabitSync.metrics.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _healthMetric == entry.key,
                        showCheckmark: false,
                        onSelected: (_) {
                          Haptics.select();
                          setState(() => _healthMetric = entry.key);
                        },
                      ),
                  ],
                ),
                if (_healthMetric != null) ...[
                  const SizedBox(height: AppSpace.md),
                  if (_type == HabitType.boolean)
                    AppTextField(
                      label:
                          'Counts as done at (${HealthHabitSync.metrics[_healthMetric]})',
                      hint: _healthMetric == 'steps' ? '8000' : '30',
                      controller: _healthTarget,
                      keyboardType: TextInputType.number,
                    )
                  else
                    Text(
                      "The day's number is logged for you. Your own log "
                      'always wins over the automatic one.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.textTertiary,
                      ),
                    ),
                ],
              ],
              if (hasLogs && _typeChanged) ...[
                const SizedBox(height: AppSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.watch,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Past logs keep their numbers — they'll be read as "
                        'the new type.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.watch,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

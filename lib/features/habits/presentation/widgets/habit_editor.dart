import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
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

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    super.dispose();
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
    try {
      if (widget.habit == null) {
        await controller.createHabit(
          name: _name.text.trim(),
          type: _type.name,
          unit: unit,
        );
      } else {
        await controller.updateHabit(widget.habit!.copyWith(
          name: _name.text.trim(),
          type: _type.name,
          unit: Value(unit),
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

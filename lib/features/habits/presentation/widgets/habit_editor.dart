import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/habits_controller.dart';
import '../../domain/habit.dart';

/// Create or edit a habit.
class HabitEditor extends ConsumerStatefulWidget {
  const HabitEditor({super.key, this.habit});

  final Habit? habit;

  static Future<void> show(BuildContext context, {Habit? habit}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(habitsControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
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
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Habit saved.')));
    } catch (_) {
      messenger
          .showSnackBar(const SnackBar(content: Text('Could not save habit.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.habit == null ? 'New habit' : 'Edit habit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Name',
              controller: _name,
              validator: (v) => Validators.required(v, label: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HabitType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final t in HabitType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) => setState(() => _type = v ?? HabitType.boolean),
            ),
            if (_type != HabitType.boolean) ...[
              const SizedBox(height: 12),
              AppTextField(
                label: 'Unit (min, hrs, reps...)',
                controller: _unit,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

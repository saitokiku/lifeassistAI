import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/time_controller.dart';
import '../../domain/time_category.dart';

/// Create or edit a weekly time budget category.
class TimeBudgetEditor extends ConsumerStatefulWidget {
  const TimeBudgetEditor({super.key, this.budget});

  final TimeBudget? budget;

  static Future<void> show(BuildContext context, {TimeBudget? budget}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => TimeBudgetEditor(budget: budget),
      );

  @override
  ConsumerState<TimeBudgetEditor> createState() => _TimeBudgetEditorState();
}

class _TimeBudgetEditorState extends ConsumerState<TimeBudgetEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.budget?.name ?? '');
  late final _hours = TextEditingController(
      text: widget.budget == null
          ? ''
          : widget.budget!.weeklyTargetHours.toString());
  late TimeCategoryKind _kind = widget.budget == null
      ? TimeCategoryKind.other
      : TimeCategoryKind.parse(widget.budget!.kind);

  @override
  void dispose() {
    _name.dispose();
    _hours.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(timeControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (widget.budget == null) {
        await controller.createBudget(
          name: _name.text.trim(),
          kind: _kind.name,
          weeklyTargetHours: Validators.parseNumber(_hours.text),
        );
      } else {
        await controller.updateBudget(widget.budget!.copyWith(
          name: _name.text.trim(),
          kind: _kind.name,
          weeklyTargetHours: Validators.parseNumber(_hours.text),
        ));
      }
      navigator.pop();
      messenger
          .showSnackBar(const SnackBar(content: Text('Time budget saved.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not save time budget.')));
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
              widget.budget == null ? 'New time budget' : 'Edit time budget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Name',
              controller: _name,
              validator: (v) => Validators.required(v, label: 'Name'),
            ),
            const SizedBox(height: 12),
            AppNumberField(
              label: 'Weekly target hours',
              controller: _hours,
              suffixText: 'h',
              validator: (v) => Validators.nonNegativeNumber(v, label: 'Hours'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TimeCategoryKind>(
              initialValue: _kind,
              decoration: const InputDecoration(
                labelText: 'Kind (drives scoring)',
                helperText:
                    'Kaizen feeds the score. Decompress feeds the recovery floor.',
              ),
              items: [
                for (final k in TimeCategoryKind.values)
                  DropdownMenuItem(value: k, child: Text(k.label)),
              ],
              onChanged: (v) =>
                  setState(() => _kind = v ?? TimeCategoryKind.other),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

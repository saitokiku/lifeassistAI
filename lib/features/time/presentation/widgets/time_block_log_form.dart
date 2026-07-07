import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/time_controller.dart';

/// Log or edit a time block against a category.
class TimeBlockLogForm extends ConsumerStatefulWidget {
  const TimeBlockLogForm({
    super.key,
    required this.budgets,
    this.block,
    this.initialBudgetId,
  });

  final List<TimeBudget> budgets;
  final TimeBlock? block;
  final String? initialBudgetId;

  static Future<void> show(
    BuildContext context, {
    required List<TimeBudget> budgets,
    TimeBlock? block,
    String? initialBudgetId,
  }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => TimeBlockLogForm(
          budgets: budgets,
          block: block,
          initialBudgetId: initialBudgetId,
        ),
      );

  @override
  ConsumerState<TimeBlockLogForm> createState() => _TimeBlockLogFormState();
}

class _TimeBlockLogFormState extends ConsumerState<TimeBlockLogForm> {
  final _formKey = GlobalKey<FormState>();
  late final _hours = TextEditingController(
      text: widget.block == null ? '' : widget.block!.hours.toString());
  late final _note = TextEditingController(text: widget.block?.note ?? '');
  late String? _budgetId = widget.block?.budgetId ??
      widget.initialBudgetId ??
      (widget.budgets.isEmpty ? null : widget.budgets.first.id);
  late DateTime _date = widget.block == null
      ? DateTime.now()
      : AppDateUtils.parseDateKey(widget.block!.date);

  @override
  void dispose() {
    _hours.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _budgetId == null) return;
    final controller = ref.read(timeControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    try {
      if (widget.block == null) {
        await controller.logBlock(
          budgetId: _budgetId!,
          date: _date,
          hours: Validators.parseNumber(_hours.text),
          note: note,
        );
      } else {
        await controller.updateBlock(widget.block!.copyWith(
          budgetId: _budgetId!,
          date: AppDateUtils.dateKey(_date),
          hours: Validators.parseNumber(_hours.text),
          note: Value(note),
        ));
      }
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Hours logged.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not log hours.')));
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
              widget.block == null ? 'Log time block' : 'Edit time block',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _budgetId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final b in widget.budgets)
                  DropdownMenuItem(value: b.id, child: Text(b.name)),
              ],
              onChanged: (v) => setState(() => _budgetId = v),
              validator: (v) => v == null ? 'Pick a category.' : null,
            ),
            const SizedBox(height: 12),
            AppNumberField(
              label: 'Hours',
              controller: _hours,
              suffixText: 'h',
              validator: (v) {
                final base = Validators.positiveNumber(v, label: 'Hours');
                if (base != null) return base;
                if (Validators.parseNumber(v!) > 24) {
                  return 'A day has 24 hours.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Note (optional)', controller: _note),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(Formatters.fullDate(_date)),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Change'),
              ),
            ),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

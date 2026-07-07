import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/identity_controller.dart';
import '../../domain/goal.dart';

/// Create or edit a goal.
class GoalsEditor extends ConsumerStatefulWidget {
  const GoalsEditor({super.key, this.goal});

  final Goal? goal;

  static Future<void> show(BuildContext context, {Goal? goal}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => GoalsEditor(goal: goal),
      );

  @override
  ConsumerState<GoalsEditor> createState() => _GoalsEditorState();
}

class _GoalsEditorState extends ConsumerState<GoalsEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.goal?.title ?? '');
  late final _description =
      TextEditingController(text: widget.goal?.description ?? '');
  late final _metricName =
      TextEditingController(text: widget.goal?.metricName ?? '');
  late final _current = TextEditingController(
      text: widget.goal == null ? '0' : widget.goal!.currentValue.toString());
  late final _target = TextEditingController(
      text: widget.goal == null ? '' : widget.goal!.targetValue.toString());
  late DateTime? _targetDate = widget.goal?.targetDate == null ||
          (widget.goal?.targetDate?.isEmpty ?? true)
      ? null
      : AppDateUtils.parseDateKey(widget.goal!.targetDate!);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _metricName.dispose();
    _current.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(identityControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final description =
        _description.text.trim().isEmpty ? null : _description.text.trim();
    final metricName =
        _metricName.text.trim().isEmpty ? null : _metricName.text.trim();
    try {
      if (widget.goal == null) {
        await controller.createGoal(
          title: _title.text.trim(),
          description: description,
          metricName: metricName,
          currentValue: Validators.parseNumber(_current.text),
          targetValue: Validators.parseNumber(_target.text),
          targetDate: _targetDate,
        );
      } else {
        await controller.updateGoal(widget.goal!.copyWith(
          title: _title.text.trim(),
          description: Value(description),
          metricName: Value(metricName),
          currentValue: Validators.parseNumber(_current.text),
          targetValue: Validators.parseNumber(_target.text),
          targetDate: Value(
              _targetDate == null ? null : AppDateUtils.dateKey(_targetDate!)),
        ));
      }
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Goal saved.')));
    } catch (_) {
      messenger
          .showSnackBar(const SnackBar(content: Text('Could not save goal.')));
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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.goal == null ? 'New goal' : 'Edit goal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Title',
                controller: _title,
                validator: (v) => Validators.required(v, label: 'Title'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Description', controller: _description, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(label: 'Metric name', controller: _metricName),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppNumberField(
                      label: 'Current',
                      controller: _current,
                      validator: (v) => Validators.number(v, label: 'Current'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppNumberField(
                      label: 'Target',
                      controller: _target,
                      validator: (v) => Validators.number(v, label: 'Target'),
                    ),
                  ),
                ],
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(_targetDate == null
                    ? 'No target date'
                    : Formatters.fullDate(_targetDate!)),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Pick date'),
                ),
              ),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}

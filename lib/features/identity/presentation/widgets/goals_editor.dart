import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/identity_controller.dart';
import '../../domain/goal.dart';
import 'target_date_row.dart';

/// Create or edit a goal.
class GoalsEditor extends ConsumerStatefulWidget {
  const GoalsEditor({super.key, this.goal});

  final Goal? goal;

  static Future<void> show(BuildContext context, {Goal? goal}) async {
    final saved = await showAppSheet<bool>(
      context,
      builder: (_) => GoalsEditor(goal: goal),
    );
    if (saved == true && context.mounted) {
      showSuccessSnack(context, 'Goal saved.');
    }
  }

  @override
  ConsumerState<GoalsEditor> createState() => _GoalsEditorState();
}

class _GoalsEditorState extends ConsumerState<GoalsEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.goal?.title ?? '');
  late final _description =
      TextEditingController(text: widget.goal?.description ?? '');
  late final _unit =
      TextEditingController(text: widget.goal?.metricName ?? '');
  late final _current = TextEditingController(
      text: widget.goal == null
          ? '0'
          : Formatters.number(widget.goal!.currentValue));
  late final _target = TextEditingController(
      text: widget.goal == null
          ? ''
          : Formatters.number(widget.goal!.targetValue));
  late DateTime? _targetDate = widget.goal?.targetDate == null ||
          (widget.goal?.targetDate?.isEmpty ?? true)
      ? null
      : AppDateUtils.parseDateKey(widget.goal!.targetDate!);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _unit.dispose();
    _current.dispose();
    _target.dispose();
    super.dispose();
  }

  String? _validateTarget(String? value) {
    final base = Validators.number(value, label: 'Target');
    if (base != null) return base;
    if (Validators.parseNumber(value!) <= 0) {
      return 'Target has to be above zero.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final controller = ref.read(identityControllerProvider);
    final description =
        _description.text.trim().isEmpty ? null : _description.text.trim();
    final metricName = _unit.text.trim().isEmpty ? null : _unit.text.trim();
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
      Haptics.medium();
      navigator.pop(true);
    } catch (_) {
      if (mounted) {
        showErrorSnack(context, "That didn't save. Try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.goal == null;

    return AppSheet(
      title: isNew ? 'New goal' : 'Edit goal',
      subtitle: isNew ? 'A number and a date. The rest is noise.' : null,
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Title',
                controller: _title,
                autofocus: isNew,
                validator: (v) => Validators.required(v, label: 'Title'),
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: 'Description (optional)',
                controller: _description,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: 'Unit (optional)',
                hint: 'e.g. subscribers',
                controller: _unit,
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: AppNumberField(
                      label: 'Current',
                      controller: _current,
                      validator: (v) =>
                          Validators.number(v, label: 'Current'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: AppNumberField(
                      label: 'Target',
                      controller: _target,
                      validator: _validateTarget,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              TargetDateRow(
                date: _targetDate,
                onChanged: (d) => setState(() => _targetDate = d),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

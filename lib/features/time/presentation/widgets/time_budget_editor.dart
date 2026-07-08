import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/time_controller.dart';
import '../../domain/time_category.dart';
import 'time_kind_icon.dart';

/// Create or edit a weekly category: name, target hours, and what the
/// hours count as for scoring.
class TimeBudgetEditor extends ConsumerStatefulWidget {
  const TimeBudgetEditor({super.key, this.budget});

  final TimeBudget? budget;

  static Future<void> show(BuildContext context, {TimeBudget? budget}) =>
      showAppSheet<void>(
        context,
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
          : Formatters.number(widget.budget!.weeklyTargetHours));
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
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
      return;
    }
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Saved.');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = widget.budget == null;

    return AppSheet(
      title: isNew ? 'New category' : 'Edit category',
      subtitle: isNew ? 'A name, a weekly target, and what it counts as.' : null,
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Name',
                controller: _name,
                validator: (v) => Validators.required(v, label: 'Name'),
              ),
              const SizedBox(height: AppSpace.md),
              AppNumberField(
                label: 'Weekly target hours',
                controller: _hours,
                suffixText: 'h',
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Hours'),
              ),
              const SizedBox(height: AppSpace.md),
              DropdownButtonFormField<TimeCategoryKind>(
                initialValue: _kind,
                decoration: const InputDecoration(
                  labelText: 'Counts as',
                  helperText: 'Scoring keys off this, not the name.',
                ),
                items: [
                  for (final k in TimeCategoryKind.values)
                    DropdownMenuItem(
                      value: k,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            k.icon,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Text(k.label),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) {
                  Haptics.select();
                  setState(() => _kind = v ?? TimeCategoryKind.other);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

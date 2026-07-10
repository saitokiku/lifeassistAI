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
import '../../../identity/application/identity_controller.dart';
import '../../../identity/domain/freedom_target.dart';
import '../../../../shared/widgets/target_date_row.dart';

/// Create or edit the long-term target.
///
/// Create collects targets only — currents start at zero and get their own
/// one-tap update path on the card, so nothing typed here is ever discarded.
class LongTermTargetEditor extends ConsumerStatefulWidget {
  const LongTermTargetEditor({super.key, this.target});

  final FreedomTarget? target;

  static Future<void> show(BuildContext context,
      {FreedomTarget? target}) async {
    final saved = await showAppSheet<bool>(
      context,
      builder: (_) => LongTermTargetEditor(target: target),
    );
    if (saved == true && context.mounted) {
      showSuccessSnack(context, target == null ? 'Target set.' : 'Saved.');
    }
  }

  @override
  ConsumerState<LongTermTargetEditor> createState() =>
      _LongTermTargetEditorState();
}

class _LongTermTargetEditorState extends ConsumerState<LongTermTargetEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.target?.title ?? '');
  late final _description =
      TextEditingController(text: widget.target?.description ?? '');
  late final _passiveTarget = TextEditingController(
      text: widget.target == null
          ? ''
          : Formatters.number(widget.target!.targetMonthlyPassiveIncome));
  late final _passiveCurrent = TextEditingController(
      text: widget.target == null
          ? ''
          : Formatters.number(widget.target!.currentMonthlyPassiveIncome));
  late final _worthTarget = TextEditingController(
      text: widget.target == null
          ? ''
          : Formatters.number(widget.target!.targetLiquidNetWorth));
  late final _worthCurrent = TextEditingController(
      text: widget.target == null
          ? ''
          : Formatters.number(widget.target!.currentLiquidNetWorth));
  late DateTime? _targetDate = (widget.target?.targetDate == null ||
          (widget.target?.targetDate?.isEmpty ?? true))
      ? null
      : AppDateUtils.parseDateKey(widget.target!.targetDate!);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _passiveTarget.dispose();
    _passiveCurrent.dispose();
    _worthTarget.dispose();
    _worthCurrent.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final controller = ref.read(identityControllerProvider);
    final description =
        _description.text.trim().isEmpty ? null : _description.text.trim();
    final t = widget.target;
    try {
      if (t == null) {
        await controller.createFreedomTarget(
          title: _title.text.trim(),
          description: description,
          targetMonthlyPassiveIncome:
              Validators.parseNumber(_passiveTarget.text),
          targetLiquidNetWorth: Validators.parseNumber(_worthTarget.text),
          targetDate: _targetDate,
        );
      } else {
        await controller.updateFreedomTarget(t.copyWith(
          title: _title.text.trim(),
          description: Value(description),
          targetMonthlyPassiveIncome:
              Validators.parseNumber(_passiveTarget.text),
          currentMonthlyPassiveIncome:
              Validators.parseNumber(_passiveCurrent.text),
          targetLiquidNetWorth: Validators.parseNumber(_worthTarget.text),
          currentLiquidNetWorth: Validators.parseNumber(_worthCurrent.text),
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
    final isNew = widget.target == null;

    return AppSheet(
      title: isNew ? 'Set a long-term target' : 'Edit long-term target',
      subtitle: isNew
          ? 'Targets only. Progress starts at zero and updates in one tap from the card.'
          : null,
      footer: AppSheetButton(
        label: isNew ? 'Set target' : 'Save',
        onPressed: _save,
      ),
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
              AppNumberField(
                label: 'Passive income target',
                controller: _passiveTarget,
                suffixText: '/mo',
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Target'),
              ),
              if (!isNew) ...[
                const SizedBox(height: AppSpace.md),
                AppNumberField(
                  label: 'Current passive income',
                  controller: _passiveCurrent,
                  suffixText: '/mo',
                  validator: (v) =>
                      Validators.nonNegativeNumber(v, label: 'Current'),
                ),
              ],
              const SizedBox(height: AppSpace.md),
              AppNumberField(
                label: 'Net worth target',
                controller: _worthTarget,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Target'),
              ),
              if (!isNew) ...[
                const SizedBox(height: AppSpace.md),
                AppNumberField(
                  label: 'Current net worth',
                  controller: _worthCurrent,
                  validator: (v) =>
                      Validators.nonNegativeNumber(v, label: 'Current'),
                ),
              ],
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

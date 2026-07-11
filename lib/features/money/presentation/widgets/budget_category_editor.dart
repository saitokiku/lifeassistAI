import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/money_controller.dart';
import '../../domain/budget_category.dart';
import '../../../../core/utils/money.dart';
import 'money_field.dart';
import 'money_snacks.dart';

/// Create or edit a budget category, including the rule that polices it.
class BudgetCategoryEditor extends ConsumerStatefulWidget {
  const BudgetCategoryEditor({super.key, this.category});

  final BudgetCategory? category;

  static Future<void> show(BuildContext context, {BudgetCategory? category}) =>
      showAppSheet<void>(
        context,
        builder: (_) => BudgetCategoryEditor(category: category),
      );

  @override
  ConsumerState<BudgetCategoryEditor> createState() =>
      _BudgetCategoryEditorState();
}

class _BudgetCategoryEditorState extends ConsumerState<BudgetCategoryEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late final _target = TextEditingController(
      text: widget.category == null
          ? ''
          : Formatters.number(
              amountFromCents(widget.category!.monthlyTargetCents),
              maxDecimals: 2));
  late BudgetFlagType _flagType = widget.category == null
      ? BudgetFlagType.warnOverTarget
      : BudgetFlagType.parse(widget.category!.flagType);

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  /// What the chosen rule actually does, in one line.
  String _ruleCaption(BudgetFlagType type) => switch (type) {
        BudgetFlagType.none => 'No flag. This lane is informational.',
        BudgetFlagType.warnOverTarget =>
          'Raises a watch flag once spend passes the monthly target.',
        BudgetFlagType.warnOverZero =>
          r'Raises a watch flag on any spend. For lanes meant to stay at $0.',
        BudgetFlagType.warnOverZeroUnlessIntentional =>
          'Flags spend unless every transaction is marked intentional.',
        BudgetFlagType.criticalOverZero =>
          'Flags any spend as critical. A hard no.',
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(moneyControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (widget.category == null) {
        await controller.createCategory(
          name: _name.text.trim(),
          monthlyTarget: Validators.parseNumber(_target.text),
          flagType: _flagType.storageKey,
        );
      } else {
        await controller.updateCategory(widget.category!.copyWith(
          name: _name.text.trim(),
          monthlyTargetCents:
              centsFromAmount(Validators.parseNumber(_target.text)),
          flagType: _flagType.storageKey,
        ));
      }
    } catch (_) {
      // Sheet stays open on failure.
      showFailedSnack(messenger, "That didn't save. Try again.");
      return;
    }
    Haptics.medium();
    navigator.pop();
    showSavedSnack(messenger, 'Saved.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSheet(
      title: widget.category == null ? 'New category' : 'Edit category',
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
                autofocus: widget.category == null,
              ),
              const SizedBox(height: AppSpace.md),
              MoneyField(
                label: 'Monthly target',
                controller: _target,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Target'),
              ),
              const SizedBox(height: AppSpace.md),
              DropdownButtonFormField<BudgetFlagType>(
                initialValue: _flagType,
                decoration: const InputDecoration(labelText: 'Flag rule'),
                items: [
                  for (final t in BudgetFlagType.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (v) {
                  Haptics.select();
                  setState(
                      () => _flagType = v ?? BudgetFlagType.warnOverTarget);
                },
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                _ruleCaption(_flagType),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

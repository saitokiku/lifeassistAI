import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/money_controller.dart';
import '../../domain/budget_category.dart';

/// Create or edit a budget category, including its flag rule.
class BudgetCategoryEditor extends ConsumerStatefulWidget {
  const BudgetCategoryEditor({super.key, this.category});

  final BudgetCategory? category;

  static Future<void> show(BuildContext context, {BudgetCategory? category}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
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
          : widget.category!.monthlyTarget.toString());
  late BudgetFlagType _flagType = widget.category == null
      ? BudgetFlagType.warnOverTarget
      : BudgetFlagType.parse(widget.category!.flagType);

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

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
          monthlyTarget: Validators.parseNumber(_target.text),
          flagType: _flagType.storageKey,
        ));
      }
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Category saved.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not save category.')));
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
              widget.category == null ? 'New category' : 'Edit category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Name',
              controller: _name,
              validator: (v) => Validators.required(v, label: 'Name'),
              autofocus: widget.category == null,
            ),
            const SizedBox(height: 12),
            AppNumberField(
              label: 'Monthly target',
              controller: _target,
              suffixText: r'$',
              validator: (v) => Validators.nonNegativeNumber(v, label: 'Target'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BudgetFlagType>(
              initialValue: _flagType,
              decoration: const InputDecoration(labelText: 'Flag rule'),
              items: [
                for (final t in BudgetFlagType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) =>
                  setState(() => _flagType = v ?? BudgetFlagType.warnOverTarget),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

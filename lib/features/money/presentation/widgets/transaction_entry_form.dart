import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/money_controller.dart';

/// Add or edit a transaction.
class TransactionEntryForm extends ConsumerStatefulWidget {
  const TransactionEntryForm({
    super.key,
    required this.categories,
    this.transaction,
  });

  final List<BudgetCategory> categories;
  final TransactionEntry? transaction;

  static Future<void> show(
    BuildContext context, {
    required List<BudgetCategory> categories,
    TransactionEntry? transaction,
  }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => TransactionEntryForm(
          categories: categories,
          transaction: transaction,
        ),
      );

  @override
  ConsumerState<TransactionEntryForm> createState() =>
      _TransactionEntryFormState();
}

class _TransactionEntryFormState extends ConsumerState<TransactionEntryForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
      text: widget.transaction == null
          ? ''
          : widget.transaction!.amount.toString());
  late final _description =
      TextEditingController(text: widget.transaction?.description ?? '');
  late String? _categoryId = widget.transaction?.categoryId;
  late bool _isIntentional = widget.transaction?.isIntentional ?? false;
  late DateTime _date = widget.transaction == null
      ? DateTime.now()
      : AppDateUtils.parseDateKey(widget.transaction!.date);

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(moneyControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (widget.transaction == null) {
        await controller.addTransaction(
          date: _date,
          amount: Validators.parseNumber(_amount.text),
          description: _description.text.trim(),
          categoryId: _categoryId,
          isIntentional: _isIntentional,
        );
      } else {
        await controller.updateTransaction(widget.transaction!.copyWith(
          date: AppDateUtils.dateKey(_date),
          amount: Validators.parseNumber(_amount.text),
          description: _description.text.trim(),
          categoryId: Value(_categoryId),
          isIntentional: _isIntentional,
        ));
      }
      navigator.pop();
      messenger
          .showSnackBar(const SnackBar(content: Text('Transaction saved.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not save transaction.')));
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
                widget.transaction == null
                    ? 'Add transaction'
                    : 'Edit transaction',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              AppNumberField(
                label: 'Amount',
                controller: _amount,
                suffixText: r'$',
                validator: (v) => Validators.positiveNumber(v, label: 'Amount'),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Description', controller: _description),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Uncategorized'),
                  ),
                  for (final c in widget.categories)
                    DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Intentional spend'),
                subtitle: const Text(
                    'Planned exceptions (e.g. a deliberate restaurant night).'),
                value: _isIntentional,
                onChanged: (v) => setState(() => _isIntentional = v),
              ),
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
      ),
    );
  }
}

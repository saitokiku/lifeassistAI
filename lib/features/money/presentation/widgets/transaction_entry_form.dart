import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/money_controller.dart';
import '../../../../core/utils/money.dart';
import 'money_field.dart';
import 'money_snacks.dart';

/// Add or edit a transaction. Built for speed: amount first (autofocused),
/// last-used category preselected, category and date handled by chips.
/// The initial* fields let the capture bus (deep links, Siri) prefill.
class TransactionEntryForm extends ConsumerStatefulWidget {
  const TransactionEntryForm({
    super.key,
    required this.categories,
    this.transaction,
    this.initialAmount,
    this.initialDescription,
    this.initialCategoryId,
  });

  final List<BudgetCategory> categories;
  final TransactionEntry? transaction;
  final double? initialAmount;
  final String? initialDescription;
  final String? initialCategoryId;

  static Future<void> show(
    BuildContext context, {
    required List<BudgetCategory> categories,
    TransactionEntry? transaction,
    double? initialAmount,
    String? initialDescription,
    String? initialCategoryId,
  }) =>
      showAppSheet<void>(
        context,
        builder: (_) => TransactionEntryForm(
          categories: categories,
          transaction: transaction,
          initialAmount: initialAmount,
          initialDescription: initialDescription,
          initialCategoryId: initialCategoryId,
        ),
      );

  @override
  ConsumerState<TransactionEntryForm> createState() =>
      _TransactionEntryFormState();
}

class _TransactionEntryFormState extends ConsumerState<TransactionEntryForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
      text: widget.transaction != null
          ? Formatters.number(
              amountFromCents(widget.transaction!.amountCents),
              maxDecimals: 2)
          : widget.initialAmount != null
              ? Formatters.number(widget.initialAmount!, maxDecimals: 2)
              : '');
  late final _description = TextEditingController(
      text: widget.transaction?.description ??
          widget.initialDescription ??
          '');
  late String? _categoryId = _initialCategoryId();
  late bool _isIntentional = widget.transaction?.isIntentional ?? false;
  late DateTime _date = widget.transaction == null
      ? DateTime.now()
      : AppDateUtils.parseDateKey(widget.transaction!.date);

  /// Editing keeps the transaction's category; a capture prefill wins next;
  /// otherwise creating starts from the most recent transaction's category
  /// so repeat spends are one tap less. Ids that don't resolve to a known
  /// category fall back to uncategorized.
  String? _initialCategoryId() {
    String? id;
    if (widget.transaction != null) {
      id = widget.transaction!.categoryId;
    } else if (widget.initialCategoryId != null) {
      id = widget.initialCategoryId;
    } else {
      final recent = ref.read(monthTransactionsProvider).valueOrNull;
      if (recent != null && recent.isNotEmpty) {
        id = recent.first.categoryId;
      }
    }
    if (id == null) return null;
    return widget.categories.any((c) => c.id == id) ? id : null;
  }

  /// Categories ordered by this month's usage (ties by sort order) so the
  /// chips the user actually hits sit first.
  List<BudgetCategory> _rankedCategories() {
    final recent =
        ref.read(monthTransactionsProvider).valueOrNull ?? const [];
    final usage = <String, int>{};
    for (final tx in recent) {
      if (tx.categoryId != null) {
        usage[tx.categoryId!] = (usage[tx.categoryId!] ?? 0) + 1;
      }
    }
    final ranked = [...widget.categories];
    ranked.sort((a, b) {
      final byUse = (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0);
      if (byUse != 0) return byUse;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return ranked;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    Haptics.select();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _date = picked);
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
          amountCents: centsFromAmount(Validators.parseNumber(_amount.text)),
          description: _description.text.trim(),
          categoryId: Value(_categoryId),
          isIntentional: _isIntentional,
        ));
      }
    } catch (_) {
      // Sheet stays open; the entry is still on screen.
      showFailedSnack(messenger, "That didn't save. Try again.");
      return;
    }
    Haptics.medium();
    navigator.pop();
    showSavedSnack(messenger, 'Logged.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final isToday = AppDateUtils.isSameDay(_date, today);
    final isYesterday = AppDateUtils.isSameDay(_date, yesterday);
    final isCustom = !isToday && !isYesterday;

    return AppSheet(
      title:
          widget.transaction == null ? 'Add transaction' : 'Edit transaction',
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoneyField(
                label: 'Amount',
                controller: _amount,
                autofocus: true,
                validator: (v) => Validators.positiveNumber(v, label: 'Amount'),
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(label: 'Description', controller: _description),
              const SizedBox(height: AppSpace.lg),
              Text(
                'CATEGORY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final c in _rankedCategories())
                    ChoiceChip(
                      label: Text(c.name),
                      selected: _categoryId == c.id,
                      showCheckmark: false,
                      onSelected: (_) {
                        Haptics.select();
                        setState(
                            () => _categoryId = _categoryId == c.id ? null : c.id);
                      },
                    ),
                  ChoiceChip(
                    label: const Text('Uncategorized'),
                    selected: _categoryId == null,
                    showCheckmark: false,
                    onSelected: (_) {
                      Haptics.select();
                      setState(() => _categoryId = null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.sm,
                children: [
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: isToday,
                    showCheckmark: false,
                    onSelected: (_) {
                      Haptics.select();
                      setState(() => _date = today);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Yesterday'),
                    selected: isYesterday,
                    showCheckmark: false,
                    onSelected: (_) {
                      Haptics.select();
                      setState(() => _date = yesterday);
                    },
                  ),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.event,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(
                      isCustom ? Formatters.shortDate(_date) : 'Pick date',
                    ),
                    selected: isCustom,
                    showCheckmark: false,
                    onSelected: (_) => _pickDate(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Intentional spend'),
                subtitle: const Text('Planned indulgence, not drift.'),
                value: _isIntentional,
                onChanged: (v) {
                  Haptics.select();
                  setState(() => _isIntentional = v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

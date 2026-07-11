import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/money_controller.dart';
import '../../../../core/utils/money.dart';
import 'money_field.dart';

/// Monthly recurring expenses: rent, subscriptions, insurance. Each one
/// lands as a real transaction on its day — no more re-typing rent.
class RecurringSheet extends ConsumerWidget {
  const RecurringSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showAppSheet<void>(context, builder: (_) => const RecurringSheet());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rows = ref.watch(recurringProvider).valueOrNull ?? const [];
    final monthlyTotalCents = rows
        .where((r) => r.active)
        .fold<int>(0, (sum, r) => sum + r.amountCents);

    return AppSheet(
      title: 'Recurring expenses',
      subtitle: rows.isEmpty
          ? 'Rent, subscriptions, insurance — each lands as a real '
              'transaction on its day of the month.'
          : '${Formatters.money(amountFromCents(monthlyTotalCents))} a month across '
              '${rows.where((r) => r.active).length} active.',
      footer: AppSheetButton(
        label: 'Add recurring expense',
        onPressed: () => RecurringEditor.show(context),
      ),
      children: [
        if (rows.isEmpty)
          Text(
            'Nothing recurring yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1),
            _RecurringRow(row: row),
          ],
      ],
    );
  }
}

class _RecurringRow extends ConsumerWidget {
  const _RecurringRow({required this.row});

  final RecurringTransaction row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: () => RecurringEditor.show(context, recurring: row),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.description.isEmpty ? 'Untitled' : row.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: row.active ? null : scheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.active
                        ? 'Day ${row.dayOfMonth} of each month'
                        : 'Paused',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              Formatters.money(amountFromCents(row.amountCents)),
              style: theme.textTheme.numberBody.copyWith(
                color: row.active ? null : scheme.textTertiary,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Switch(
              value: row.active,
              onChanged: (v) {
                Haptics.select();
                ref
                    .read(moneyControllerProvider)
                    .updateRecurring(row.copyWith(active: v));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Create or edit one recurring expense.
class RecurringEditor extends ConsumerStatefulWidget {
  const RecurringEditor({super.key, this.recurring});

  final RecurringTransaction? recurring;

  static Future<void> show(BuildContext context,
          {RecurringTransaction? recurring}) =>
      showAppSheet<void>(
        context,
        builder: (_) => RecurringEditor(recurring: recurring),
      );

  @override
  ConsumerState<RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends ConsumerState<RecurringEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _description =
      TextEditingController(text: widget.recurring?.description ?? '');
  late final _amount = TextEditingController(
      text: widget.recurring == null
          ? ''
          : Formatters.number(
              amountFromCents(widget.recurring!.amountCents),
              maxDecimals: 2));
  late int _dayOfMonth = widget.recurring?.dayOfMonth ?? 1;
  late String? _categoryId = widget.recurring?.categoryId;
  bool _busy = false;

  bool get _editing => widget.recurring != null;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    _busy = true;
    final controller = ref.read(moneyControllerProvider);
    final navigator = Navigator.of(context);
    try {
      if (widget.recurring == null) {
        await controller.createRecurring(
          amount: Validators.parseNumber(_amount.text),
          description: _description.text.trim(),
          dayOfMonth: _dayOfMonth,
          categoryId: _categoryId,
        );
      } else {
        await controller.updateRecurring(widget.recurring!.copyWith(
          amountCents: centsFromAmount(Validators.parseNumber(_amount.text)),
          description: _description.text.trim(),
          dayOfMonth: _dayOfMonth,
          categoryId: Value(_categoryId),
        ));
      }
    } catch (_) {
      _busy = false;
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
      return;
    }
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Saved.');
    navigator.pop();
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(moneyControllerProvider)
          .deleteRecurring(widget.recurring!.id);
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't delete. Try again.");
      return;
    }
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Recurring expense deleted.');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories =
        ref.watch(budgetCategoriesProvider).valueOrNull ?? const [];

    return AppSheet(
      title: _editing ? 'Edit recurring expense' : 'New recurring expense',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetButton(label: 'Save', onPressed: _save),
          if (_editing) ...[
            const SizedBox(height: AppSpace.sm),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.critical),
              onPressed: _delete,
              child: const Text('Delete'),
            ),
          ],
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Description',
                hint: 'e.g. Rent',
                controller: _description,
                autofocus: !_editing,
                validator: (v) => Validators.required(v, label: 'Description'),
              ),
              const SizedBox(height: AppSpace.md),
              MoneyField(
                label: 'Amount',
                controller: _amount,
                validator: (v) => Validators.positiveNumber(v, label: 'Amount'),
              ),
              const SizedBox(height: AppSpace.md),
              DropdownButtonFormField<int>(
                initialValue: _dayOfMonth,
                decoration: const InputDecoration(labelText: 'Day of month'),
                items: [
                  for (var d = 1; d <= 31; d++)
                    DropdownMenuItem(
                      value: d,
                      child: Text(
                        d == 31 ? '31 (or last day)' : '$d',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                    ),
                ],
                onChanged: (v) {
                  Haptics.select();
                  setState(() => _dayOfMonth = v ?? 1);
                },
              ),
              const SizedBox(height: AppSpace.md),
              DropdownButtonFormField<String?>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Uncategorized'),
                  ),
                  for (final c in categories)
                    DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                ],
                onChanged: (v) {
                  Haptics.select();
                  setState(() => _categoryId = v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

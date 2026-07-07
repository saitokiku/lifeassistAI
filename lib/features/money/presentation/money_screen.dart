import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validation.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_number_field.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/progress_bar_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/money_controller.dart';
import '../application/money_state.dart';
import 'widgets/budget_category_editor.dart';
import 'widgets/budget_category_list.dart';
import 'widgets/money_flags_card.dart';
import 'widgets/surplus_card.dart';
import 'widgets/transaction_entry_form.dart';
import 'widgets/transactions_list.dart';

/// Money module: surplus, budgets, transactions, flags, freedom accounts.
class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moneyStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Money')),
      floatingActionButton: state == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => TransactionEntryForm.show(context,
                  categories: state.categories),
              icon: const Icon(Icons.add),
              label: const Text('Transaction'),
            ),
      body: state == null
          ? const LoadingView()
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  SurplusCard(
                    snapshot: state.snapshot,
                    onEditIncome: () => _showIncomeEditor(context, ref, state),
                  ),
                  const SizedBox(height: 12),
                  MoneyFlagsCard(flags: state.snapshot.flags),
                  const SizedBox(height: 12),
                  MetricCard(
                    title: 'Freedom accounts',
                    supportText: 'Manual balances. Update monthly.',
                    child: Column(
                      children: [
                        LabeledProgressBar(
                          progress: state.snapshot.rothIraProgress,
                          color: AppColors.primary,
                          leading:
                              'Roth IRA · ${Formatters.money(state.snapshot.rothIraContributed)} of ${Formatters.money(state.snapshot.rothIraAnnualTarget)}',
                          trailing:
                              Formatters.percent(state.snapshot.rothIraProgress),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Brokerage ${Formatters.money(state.snapshot.brokerageBalance)} · Savings ${Formatters.money(state.snapshot.savingsBalance)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _showAccountsEditor(context, ref, state),
                              child: const Text('Edit'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SectionHeader(
                    title: 'Budget categories',
                    trailing: TextButton.icon(
                      onPressed: () => BudgetCategoryEditor.show(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New'),
                    ),
                  ),
                  BudgetCategoryList(
                      categorySpends: state.snapshot.categorySpends),
                  const SectionHeader(title: 'Transactions this month'),
                  TransactionsList(state: state),
                ],
              ),
            ),
    );
  }

  void _showIncomeEditor(BuildContext context, WidgetRef ref, MoneyState state) {
    final income = TextEditingController(
        text: state.snapshot.monthlyNetIncome.toString());
    final low = TextEditingController(
        text: state.snapshot.targetSurplusLow.toString());
    final high = TextEditingController(
        text: state.snapshot.targetSurplusHigh.toString());
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Income & surplus targets',
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 16),
              AppNumberField(
                label: 'Net monthly income',
                controller: income,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Income'),
              ),
              const SizedBox(height: 12),
              AppNumberField(
                label: 'Target surplus low',
                controller: low,
                validator: (v) => Validators.number(v, label: 'Low target'),
              ),
              const SizedBox(height: 12),
              AppNumberField(
                label: 'Target surplus high',
                controller: high,
                validator: (v) => Validators.number(v, label: 'High target'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final controller = ref.read(moneyControllerProvider);
                  final navigator = Navigator.of(sheetContext);
                  await controller.setMonthlyNetIncome(
                      Validators.parseNumber(income.text));
                  await controller.setTargetSurplus(
                    low: Validators.parseNumber(low.text),
                    high: Validators.parseNumber(high.text),
                  );
                  navigator.pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountsEditor(BuildContext context, WidgetRef ref, MoneyState state) {
    final target = TextEditingController(
        text: state.snapshot.rothIraAnnualTarget.toString());
    final contributed = TextEditingController(
        text: state.snapshot.rothIraContributed.toString());
    final brokerage = TextEditingController(
        text: state.snapshot.brokerageBalance.toString());
    final savings =
        TextEditingController(text: state.snapshot.savingsBalance.toString());
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Freedom accounts',
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 16),
              AppNumberField(
                label: 'Roth IRA annual target',
                controller: target,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Target'),
              ),
              const SizedBox(height: 12),
              AppNumberField(
                label: 'Roth IRA contributed this year',
                controller: contributed,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Contributed'),
              ),
              const SizedBox(height: 12),
              AppNumberField(
                label: 'Brokerage balance',
                controller: brokerage,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Balance'),
              ),
              const SizedBox(height: 12),
              AppNumberField(
                label: 'Savings balance',
                controller: savings,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Balance'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final controller = ref.read(moneyControllerProvider);
                  final navigator = Navigator.of(sheetContext);
                  await controller.setRothIra(
                    annualTarget: Validators.parseNumber(target.text),
                    contributed: Validators.parseNumber(contributed.text),
                  );
                  await controller.setBalances(
                    brokerage: Validators.parseNumber(brokerage.text),
                    savings: Validators.parseNumber(savings.text),
                  );
                  navigator.pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

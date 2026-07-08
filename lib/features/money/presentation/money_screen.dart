import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../settings/application/settings_controller.dart';
import '../application/money_controller.dart';
import 'widgets/budget_category_editor.dart';
import 'widgets/budget_category_list.dart';
import 'widgets/freedom_accounts_card.dart';
import 'widgets/freedom_accounts_sheet.dart';
import 'widgets/income_targets_sheet.dart';
import 'widgets/money_flags_card.dart';
import 'widgets/surplus_card.dart';
import 'widgets/surplus_history_chart.dart';
import 'widgets/transaction_entry_form.dart';
import 'widgets/transactions_list.dart';

/// Money — the scoreboard. Projected surplus leads; flags, history,
/// freedom accounts, budgets, and the transaction log support it.
class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(moneyStateProvider);

    if (state == null) {
      // The combined provider collapses errors to null; watch the sources
      // directly so a broken stream shows a retry, not an eternal spinner.
      final hasError = ref.watch(settingsProvider).hasError ||
          ref.watch(budgetCategoriesProvider).hasError ||
          ref.watch(monthTransactionsProvider).hasError;
      return Scaffold(
        body: SafeArea(
          child: hasError
              ? ErrorState(
                  title: "The scoreboard didn't load.",
                  message: 'Your data is safe. Give it another try.',
                  onRetry: () {
                    ref.invalidate(settingsProvider);
                    ref.invalidate(budgetCategoriesProvider);
                    ref.invalidate(monthTransactionsProvider);
                  },
                )
              : const SkeletonList(),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            TransactionEntryForm.show(context, categories: state.categories),
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.lg,
              AppSpace.screen,
              96,
            ),
            children: [
              Text('Money', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpace.xs),
              Text(
                'The scoreboard, not the mission.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              SurplusCard(
                snapshot: state.snapshot,
                onEditIncome: () => IncomeTargetsSheet.show(
                  context,
                  snapshot: state.snapshot,
                ),
              ),
              const SizedBox(height: AppSpace.cardGap),
              MoneyFlagsCard(flags: state.snapshot.flags),
              const SizedBox(height: AppSpace.cardGap),
              SurplusHistoryChart(
                targetSurplusLow: state.snapshot.targetSurplusLow,
              ),
              const SizedBox(height: AppSpace.cardGap),
              FreedomAccountsCard(
                snapshot: state.snapshot,
                onEdit: () => FreedomAccountsSheet.show(
                  context,
                  snapshot: state.snapshot,
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
                categorySpends: state.snapshot.categorySpends,
              ),
              SectionHeader(
                title: 'Transactions',
                trailing: Text(
                  Formatters.moneyCents(state.snapshot.spendSoFar),
                  style: theme.textTheme.numberBody.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
              TransactionsList(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

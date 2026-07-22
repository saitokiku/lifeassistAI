import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/haptics.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../identity/application/identity_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../application/money_controller.dart';
import 'widgets/accounts_card.dart';
import 'widgets/budget_category_editor.dart';
import 'widgets/budget_category_list.dart';
import 'widgets/csv_import_sheet.dart';
import 'widgets/income_targets_sheet.dart';
import 'widgets/long_term_target_card.dart';
import 'widgets/money_flags_card.dart';
import 'widgets/recurring_sheet.dart';
import 'widgets/savings_accounts_card.dart';
import 'widgets/savings_accounts_sheet.dart';
import 'widgets/surplus_card.dart';
import 'widgets/surplus_history_chart.dart';
import 'widgets/transaction_entry_form.dart';
import 'widgets/transactions_list.dart';
import '../../../ui/tab_page_header.dart';

/// Money — where the month stands. Projected surplus leads; flags, history,
/// budgets, the transaction log, and the long game support it.
class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Materialize due recurring expenses; re-runs on day rollover.
    ref.watch(recurringMaterializerProvider);
    final state = ref.watch(viewedMoneyStateProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final monthOffset = ref.watch(viewedMonthOffsetProvider);
    final viewedMonth = ref.watch(viewedMonthProvider);
    final longTermTarget =
        ref.watch(freedomTargetsProvider).valueOrNull?.firstOrNull;

    if (state == null || settings == null) {
      // The combined provider collapses errors to null; watch the sources
      // directly so a broken stream shows a retry, not an eternal spinner.
      final hasError = ref.watch(settingsProvider).hasError ||
          ref.watch(budgetCategoriesProvider).hasError ||
          ref.watch(monthTransactionsProvider).hasError;
      return Scaffold(
        body: SafeArea(
          child: hasError
              ? ErrorState(
                  title: "Money didn't load.",
                  message: AppCopy.dataSafeRetry,
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

    final hasIncome = settings.hasIncome;
    final isCurrentMonth = monthOffset == 0;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            TransactionEntryForm.show(context, categories: state.categories),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
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
              TabPageHeader(
                title: 'Money',
                actions: [
                  _MonthStepper(
                    month: viewedMonth,
                    isCurrent: isCurrentMonth,
                    onPrevious: () {
                      Haptics.select();
                      ref.read(viewedMonthOffsetProvider.notifier).state =
                          monthOffset + 1;
                    },
                    onNext: isCurrentMonth
                        ? null
                        : () {
                            Haptics.select();
                            ref.read(viewedMonthOffsetProvider.notifier).state =
                                monthOffset - 1;
                          },
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                isCurrentMonth
                    ? AppCopy.moneyTagline
                    : 'A finished month — numbers are final, still editable.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              if (!hasIncome)
                _IncomeSetupCard(
                  onSetup: () => IncomeTargetsSheet.show(
                    context,
                    snapshot: state.snapshot,
                  ),
                )
              else ...[
                SurplusCard(
                  snapshot: state.snapshot,
                  onEditIncome: () => IncomeTargetsSheet.show(
                    context,
                    snapshot: state.snapshot,
                  ),
                ),
                const SizedBox(height: AppSpace.cardGap),
                MoneyFlagsCard(flags: state.snapshot.flags),
                if (isCurrentMonth) ...[
                  const SizedBox(height: AppSpace.cardGap),
                  SurplusHistoryChart(
                    targetSurplusLow: state.snapshot.targetSurplusLow,
                  ),
                ],
              ],
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Formatters.moneyCents(state.snapshot.spendSoFar),
                      style: theme.textTheme.numberBody.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Transaction tools',
                      icon: Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: theme.colorScheme.textTertiary,
                      ),
                      onSelected: (value) {
                        if (value == 'import') CsvImportSheet.show(context);
                        if (value == 'recurring') RecurringSheet.show(context);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'import',
                          child: Text('Import statement (CSV)'),
                        ),
                        PopupMenuItem(
                          value: 'recurring',
                          child: Text('Recurring expenses'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TransactionsList(state: state),
              const SectionHeader(title: 'The long game'),
              const AccountsCard(),
              const SizedBox(height: AppSpace.cardGap),
              SavingsAccountsCard(
                snapshot: state.snapshot,
                onEdit: () => SavingsAccountsSheet.show(
                  context,
                  snapshot: state.snapshot,
                ),
              ),
              const SizedBox(height: AppSpace.cardGap),
              LongTermTargetCard(target: longTermTarget),
            ],
          ),
        ),
      ),
    );
  }
}

/// ‹ July 2026 › — steps whole months; forward stops at the present.
class _MonthStepper extends StatelessWidget {
  const _MonthStepper({
    required this.month,
    required this.isCurrent,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final bool isCurrent;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  static final _fmt = DateFormat('MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous month',
          visualDensity: VisualDensity.compact,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
        ),
        Text(
          isCurrent ? 'This month' : _fmt.format(month),
          style: theme.textTheme.labelMedium?.copyWith(
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          visualDensity: VisualDensity.compact,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded, size: 22),
        ),
      ],
    );
  }
}

/// First-run state: the month's picture needs one number to exist.
class _IncomeSetupCard extends StatelessWidget {
  const _IncomeSetupCard({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.chip + 2),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Text(
                  'See where the month stands',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'Add your monthly income and the app projects spending, '
            'surplus, and pace from what you log. Two numbers, '
            'thirty seconds.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          FilledButton(
            onPressed: onSetup,
            child: const Text('Set income'),
          ),
        ],
      ),
    );
  }
}

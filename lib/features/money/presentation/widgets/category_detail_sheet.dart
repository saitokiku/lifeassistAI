import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/money_controller.dart';
import '../../domain/budget_category.dart';
import '../../domain/monthly_money_snapshot.dart';
import '../../domain/transaction_entry.dart';
import 'money_chips.dart';
import 'money_snacks.dart';
import 'transaction_entry_form.dart';

/// One category, up close: rule, pace against target, and this month's
/// transactions with an inline intentional switch — the one-tap way to
/// clear a "not marked intentional" flag. A null [categoryId] shows the
/// uncategorized bucket instead.
class CategoryDetailSheet extends ConsumerWidget {
  const CategoryDetailSheet({super.key, this.categoryId});

  final String? categoryId;

  static Future<void> show(BuildContext context, {String? categoryId}) =>
      showAppSheet<void>(
        context,
        builder: (_) => CategoryDetailSheet(categoryId: categoryId),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(moneyStateProvider);
    if (state == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpace.xxxl * 2),
        child: SizedBox(
          height: 120,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ),
      );
    }

    CategorySpend? cs;
    if (categoryId != null) {
      for (final candidate in state.snapshot.categorySpends) {
        if (candidate.category.id == categoryId) {
          cs = candidate;
          break;
        }
      }
      if (cs == null) {
        // Deleted while the sheet was open — say so instead of guessing.
        return AppSheet(
          title: 'Category',
          children: [
            Text(
              'This category is gone. Its transactions moved to uncategorized.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        );
      }
    }

    final transactions = [
      for (final tx in state.monthTransactions)
        if (tx.categoryId == categoryId) tx,
    ];

    return AppSheet(
      title: cs?.category.name ?? 'Uncategorized',
      subtitle: cs == null
          ? 'Spending without a lane. Tap a row to give it one.'
          : 'Tap a row to edit. The switch marks it intentional.',
      children: [
        if (cs != null) ...[
          _CategoryPace(cs: cs),
          const SizedBox(height: AppSpace.xl),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                'THIS MONTH',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.textTertiary,
                ),
              ),
            ),
            Text(
              '${transactions.length} transaction${transactions.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Text(
              'Nothing logged here this month.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final tx in transactions)
            _SheetTransactionRow(
              tx: tx,
              categories: state.categories,
            ),
      ],
    );
  }
}

/// Rule chip + spend/target bar with explicit over/left amount.
class _CategoryPace extends StatelessWidget {
  const _CategoryPace({required this.cs});

  final CategorySpend cs;

  @override
  Widget build(BuildContext context) {
    final target = cs.category.monthlyTarget;
    final over = cs.spent > target;
    final ruleType = BudgetFlagType.parse(cs.category.flagType);
    final ruleLabel = flagRuleChipLabel(ruleType, target);
    final barColor = over
        ? (target <= 0 ? AppColors.critical : AppColors.watch)
        : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ruleLabel != null) ...[
          MoneyChip(
            label: ruleLabel,
            color: flagRuleIsCritical(ruleType) ? AppColors.critical : null,
          ),
          const SizedBox(height: AppSpace.md),
        ],
        LabeledProgressBar(
          progress: cs.progress,
          color: barColor,
          leading:
              '${Formatters.money(cs.spent)} of ${Formatters.money(target)}',
          trailing: over
              ? '${Formatters.money(cs.spent - target)} over'
              : '${Formatters.money(cs.remaining)} left',
        ),
      ],
    );
  }
}

class _SheetTransactionRow extends ConsumerWidget {
  const _SheetTransactionRow({required this.tx, required this.categories});

  final TransactionEntry tx;
  final List<BudgetCategory> categories;

  Future<void> _toggleIntentional(
      BuildContext context, WidgetRef ref, bool value) async {
    Haptics.select();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(moneyControllerProvider)
          .updateTransaction(tx.copyWith(isIntentional: value));
    } catch (_) {
      showFailedSnack(messenger, "That didn't save. Try again.");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasDescription = tx.description.isNotEmpty;
    final date = AppDateUtils.parseDateKey(tx.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => TransactionEntryForm.show(
                context,
                categories: categories,
                transaction: tx,
              ),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasDescription ? tx.description : 'No description',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: hasDescription
                                ? theme.textTheme.bodyMedium
                                : theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.textTertiary,
                                  ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            Formatters.shortDate(date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      Formatters.moneyCents(tx.amount),
                      style: theme.textTheme.numberBody,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Semantics(
            label: 'Intentional spend',
            child: Switch(
              value: tx.isIntentional,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) => _toggleIntentional(context, ref, v),
            ),
          ),
        ],
      ),
    );
  }
}

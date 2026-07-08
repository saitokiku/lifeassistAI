import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/money_controller.dart';
import '../../domain/budget_category.dart';
import '../../domain/monthly_money_snapshot.dart';
import 'budget_category_editor.dart';
import 'category_detail_sheet.dart';
import 'money_chips.dart';
import 'money_snacks.dart';

/// Month-to-date spend per category. Tap a row for the detail sheet;
/// the overflow menu keeps edit and delete visible.
class BudgetCategoryList extends ConsumerWidget {
  const BudgetCategoryList({super.key, required this.categorySpends});

  final List<CategorySpend> categorySpends;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categorySpends.isEmpty) {
      return EmptyState(
        icon: Icons.donut_small_outlined,
        title: 'No categories yet',
        message:
            'Give the money lanes. Categories turn raw spend into signal.',
        actionLabel: 'Add category',
        onAction: () => BudgetCategoryEditor.show(context),
      );
    }

    return Column(
      children: [
        for (final (i, cs) in categorySpends.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.sm),
          _CategoryRow(cs: cs),
        ],
      ],
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.cs});

  final CategorySpend cs;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete category?',
      message: 'Transactions in "${cs.category.name}" become uncategorized.',
    );
    if (!confirmed) return;
    try {
      await ref.read(moneyControllerProvider).deleteCategory(cs.category.id);
    } catch (_) {
      showFailedSnack(messenger, "That didn't delete. Try again.");
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Deleted. Its transactions are now uncategorized.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final target = cs.category.monthlyTarget;
    final over = cs.spent > target;
    final ruleType = BudgetFlagType.parse(cs.category.flagType);
    final ruleLabel = flagRuleChipLabel(ruleType, target);
    final barColor = over
        ? (target <= 0 ? AppColors.critical : AppColors.watch)
        : AppColors.primary;

    return AppCard(
      onTap: () =>
          CategoryDetailSheet.show(context, categoryId: cs.category.id),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.sm,
        AppSpace.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cs.category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (ruleLabel != null) ...[
                      const SizedBox(width: AppSpace.sm),
                      MoneyChip(
                        label: ruleLabel,
                        color: flagRuleIsCritical(ruleType)
                            ? AppColors.critical
                            : null,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                LabeledProgressBar(
                  progress: cs.progress,
                  color: barColor,
                  trailing:
                      '${Formatters.money(cs.spent)} / ${Formatters.money(target)}',
                ),
                if (over) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    '${Formatters.money(cs.spent - target)} over',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: barColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              size: 18,
              color: theme.colorScheme.textTertiary,
            ),
            onSelected: (value) async {
              if (value == 'edit') {
                await BudgetCategoryEditor.show(context,
                    category: cs.category);
              } else if (value == 'delete') {
                await _delete(context, ref);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/money_controller.dart';
import '../../domain/monthly_money_snapshot.dart';
import 'budget_category_editor.dart';

/// Month-to-date spend per category with edit/delete.
class BudgetCategoryList extends ConsumerWidget {
  const BudgetCategoryList({super.key, required this.categorySpends});

  final List<CategorySpend> categorySpends;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final cs in categorySpends)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledProgressBar(
                          progress: cs.progress,
                          color: cs.spent > cs.category.monthlyTarget
                              ? (cs.category.monthlyTarget <= 0
                                  ? AppColors.critical
                                  : AppColors.watch)
                              : AppColors.primary,
                          leading: cs.category.name,
                          trailing:
                              '${Formatters.money(cs.spent)} / ${Formatters.money(cs.category.monthlyTarget)}',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await BudgetCategoryEditor.show(context,
                            category: cs.category);
                      } else if (value == 'delete') {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Delete category?',
                          message:
                              'Transactions in "${cs.category.name}" become uncategorized.',
                        );
                        if (confirmed) {
                          await ref
                              .read(moneyControllerProvider)
                              .deleteCategory(cs.category.id);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

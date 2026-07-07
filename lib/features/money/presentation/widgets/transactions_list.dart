import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../application/money_controller.dart';
import '../../application/money_state.dart';
import 'transaction_entry_form.dart';

/// This month's transactions with edit/delete.
class TransactionsList extends ConsumerWidget {
  const TransactionsList({super.key, required this.state});

  final MoneyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = state.monthTransactions;
    if (transactions.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions this month',
        message: 'Log spend as it happens. The projection needs real data.',
        actionLabel: 'Add transaction',
        onAction: () =>
            TransactionEntryForm.show(context, categories: state.categories),
      );
    }

    return Column(
      children: [
        for (final tx in transactions)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                tx.description.isEmpty ? '(no description)' : tx.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                [
                  state.categoryById(tx.categoryId)?.name ?? 'Uncategorized',
                  Formatters.shortDate(AppDateUtils.parseDateKey(tx.date)),
                  if (tx.isIntentional) 'intentional',
                ].join(' · '),
              ),
              leading: tx.categoryId == null
                  ? const Icon(Icons.help_outline, color: AppColors.watch)
                  : const Icon(Icons.receipt_outlined),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.moneyCents(tx.amount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await TransactionEntryForm.show(
                          context,
                          categories: state.categories,
                          transaction: tx,
                        );
                      } else if (value == 'delete') {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Delete transaction?',
                          message:
                              'Removes ${Formatters.moneyCents(tx.amount)} from this month.',
                        );
                        if (confirmed) {
                          await ref
                              .read(moneyControllerProvider)
                              .deleteTransaction(tx.id);
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

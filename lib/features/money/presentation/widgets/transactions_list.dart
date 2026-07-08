import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/money_controller.dart';
import '../../application/money_state.dart';
import '../../domain/transaction_entry.dart';
import 'money_chips.dart';
import 'money_snacks.dart';
import 'transaction_entry_form.dart';

/// This month's transactions grouped by day. Row tap edits; swipe (or the
/// overflow menu) deletes with an undo — these rows are cheap to recreate.
class TransactionsList extends ConsumerStatefulWidget {
  const TransactionsList({super.key, required this.state});

  final MoneyState state;

  @override
  ConsumerState<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends ConsumerState<TransactionsList> {
  /// Rows removed optimistically while their delete is in flight, so
  /// Dismissible never finds a dismissed row still in the tree.
  final _pendingDelete = <String>{};

  Future<void> _delete(TransactionEntry tx) async {
    Haptics.medium();
    setState(() => _pendingDelete.add(tx.id));
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(moneyControllerProvider);
    try {
      await controller.deleteTransaction(tx.id);
    } catch (_) {
      if (mounted) setState(() => _pendingDelete.remove(tx.id));
      showFailedSnack(messenger, "That didn't delete. Try again.");
      return;
    }
    if (!mounted) return;
    showUndoSnack(
      context,
      '${Formatters.moneyCents(tx.amount)} removed.',
      onUndo: () {
        unawaited(
          controller
              .addTransaction(
                date: AppDateUtils.parseDateKey(tx.date),
                amount: tx.amount,
                description: tx.description,
                categoryId: tx.categoryId,
                isIntentional: tx.isIntentional,
              )
              .catchError(
                  (_) => showFailedSnack(messenger, "That didn't restore.")),
        );
      },
    );
  }

  String _dayLabel(DateTime day) {
    final now = widget.state.now;
    if (AppDateUtils.isSameDay(day, now)) return 'Today';
    if (AppDateUtils.isSameDay(
        day, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return Formatters.shortDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.state.monthTransactions;
    // Ids that have left the stream no longer need filtering.
    _pendingDelete
        .removeWhere((id) => !all.any((t) => t.id == id));
    final transactions = [
      for (final t in all)
        if (!_pendingDelete.contains(t.id)) t,
    ];

    if (all.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No spending logged this month yet',
        message: 'Log spend as it happens. The projection needs real data.',
        actionLabel: 'Add transaction',
        onAction: () => TransactionEntryForm.show(context,
            categories: widget.state.categories),
      );
    }

    // Group by day; the repo already orders date desc, createdAt desc.
    final groups = <String, List<TransactionEntry>>{};
    for (final tx in transactions) {
      groups.putIfAbsent(tx.date, () => []).add(tx);
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpace.md,
              bottom: AppSpace.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dayLabel(AppDateUtils.parseDateKey(entry.key)),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  Formatters.moneyCents(
                    entry.value.fold<double>(0, (sum, t) => sum + t.amount),
                  ),
                  style: theme.textTheme.numberBody.copyWith(
                    color: theme.colorScheme.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          for (final (i, tx) in entry.value.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpace.sm),
            _TransactionRow(
              tx: tx,
              state: widget.state,
              onDelete: () => _delete(tx),
            ),
          ],
        ],
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.tx,
    required this.state,
    required this.onDelete,
  });

  final TransactionEntry tx;
  final MoneyState state;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryName = state.categoryById(tx.categoryId)?.name;
    final hasDescription = tx.description.isNotEmpty;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.xl),
        decoration: BoxDecoration(
          color: AppColors.critical.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.critical),
      ),
      child: AppCard(
        onTap: () => TransactionEntryForm.show(
          context,
          categories: state.categories,
          transaction: tx,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
        ),
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
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      Flexible(
                        child: MoneyChip(
                          label: categoryName ?? 'Uncategorized',
                          color: categoryName == null
                              ? AppColors.watch
                              : null,
                        ),
                      ),
                      if (tx.isIntentional) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Intentional spend',
                          child: Icon(
                            Icons.task_alt,
                            size: 14,
                            color: AppColors.primary
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              Formatters.moneyCents(tx.amount),
              style: theme.textTheme.numberBody,
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: theme.colorScheme.textTertiary,
              ),
              onSelected: (value) async {
                if (value == 'edit') {
                  await TransactionEntryForm.show(
                    context,
                    categories: state.categories,
                    transaction: tx,
                  );
                } else if (value == 'delete') {
                  onDelete();
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
    );
  }
}

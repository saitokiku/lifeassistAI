import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../application/time_controller.dart';
import 'time_block_log_form.dart';

/// Recent time blocks with edit/delete.
class TimeBlockHistoryList extends ConsumerWidget {
  const TimeBlockHistoryList({
    super.key,
    required this.blocks,
    required this.budgets,
  });

  final List<TimeBlock> blocks;
  final List<TimeBudget> budgets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (blocks.isEmpty) {
      return EmptyState(
        icon: Icons.timer_outlined,
        title: 'No time logged yet',
        message: 'Log real hours. The dashboard runs on them.',
        actionLabel: 'Log time',
        onAction: () => TimeBlockLogForm.show(context, budgets: budgets),
      );
    }

    final budgetById = {for (final b in budgets) b.id: b};

    return Column(
      children: [
        for (final block in blocks)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(budgetById[block.budgetId]?.name ?? 'Unknown'),
              subtitle: Text([
                Formatters.shortDate(AppDateUtils.parseDateKey(block.date)),
                if (block.note?.isNotEmpty ?? false) block.note!,
              ].join(' · ')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.hours(block.hours),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await TimeBlockLogForm.show(
                          context,
                          budgets: budgets,
                          block: block,
                        );
                      } else if (value == 'delete') {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Delete time block?',
                          message:
                              'Removes ${Formatters.hours(block.hours)} logged on ${block.date}.',
                        );
                        if (confirmed) {
                          await ref
                              .read(timeControllerProvider)
                              .deleteBlock(block.id);
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

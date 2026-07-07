import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/time_controller.dart';
import '../application/time_state.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'widgets/available_time_card.dart';
import 'widgets/countdown_editor.dart';
import 'widgets/countdown_list.dart';
import 'widgets/time_block_history_list.dart';
import 'widgets/time_block_log_form.dart';
import 'widgets/time_budget_editor.dart';
import 'widgets/weekly_time_budget_card.dart';

/// Time module: weekly budgets, logged blocks, countdowns.
class TimeScreen extends ConsumerWidget {
  const TimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeStateProvider);
    final recentBlocks = ref.watch(recentTimeBlocksProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Time')),
      floatingActionButton: state == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  TimeBlockLogForm.show(context, budgets: state.budgets),
              icon: const Icon(Icons.add),
              label: const Text('Log time'),
            ),
      body: state == null
          ? const LoadingView()
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  AvailableTimeCard(state: state),
                  const SizedBox(height: 12),
                  WeeklyTimeBudgetCard(
                    state: state,
                    onEdit: () => _showBudgetManager(context, ref, state),
                  ),
                  SectionHeader(
                    title: 'Countdowns',
                    trailing: TextButton.icon(
                      onPressed: () => CountdownEditor.show(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New'),
                    ),
                  ),
                  CountdownList(countdowns: state.countdowns),
                  const SectionHeader(title: 'Recent time blocks'),
                  TimeBlockHistoryList(
                    blocks: recentBlocks ?? state.weekBlocks,
                    budgets: state.budgets,
                  ),
                ],
              ),
            ),
    );
  }

  void _showBudgetManager(BuildContext context, WidgetRef ref, TimeState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Weekly targets',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed: () => TimeBudgetEditor.show(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final budget in state.budgets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(budget.name),
                subtitle: Text('${budget.weeklyTargetHours}h / week'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () =>
                          TimeBudgetEditor.show(context, budget: budget),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Delete time budget?',
                          message:
                              'Deletes "${budget.name}" and its logged blocks.',
                        );
                        if (confirmed) {
                          await ref
                              .read(timeControllerProvider)
                              .deleteBudget(budget.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/time_controller.dart';
import '../application/time_state.dart';
import 'widgets/available_time_card.dart';
import 'widgets/budget_manager_sheet.dart';
import 'widgets/countdown_editor.dart';
import 'widgets/countdown_list.dart';
import 'widgets/time_block_history_list.dart';
import 'widgets/time_block_log_form.dart';
import 'widgets/weekly_hours_chart.dart';
import 'widgets/weekly_time_budget_card.dart';

/// Time — where hours get pointed. Weekly targets, the history chart,
/// countdowns, and the log everything else runs on.
class TimeScreen extends ConsumerWidget {
  const TimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeStateProvider);
    final recentBlocks = ref.watch(recentTimeBlocksProvider).valueOrNull;

    // timeStateProvider collapses stream errors to null; watch the sources
    // directly so a broken stream shows a retry instead of a forever-spinner.
    final hasError = ref.watch(timeBudgetsProvider).hasError ||
        ref.watch(weekTimeBlocksProvider).hasError ||
        ref.watch(countdownsProvider).hasError ||
        ref.watch(recentTimeBlocksProvider).hasError;

    return Scaffold(
      floatingActionButton: state == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  TimeBlockLogForm.show(context, budgets: state.budgets),
              icon: const Icon(Icons.add),
              label: const Text('Log time'),
            ),
      body: SafeArea(
        child: state != null
            ? _Content(state: state, recentBlocks: recentBlocks)
            : hasError
                ? ErrorState(onRetry: () => _retry(ref))
                : const SkeletonList(),
      ),
    );
  }

  void _retry(WidgetRef ref) {
    ref.invalidate(timeBudgetsProvider);
    ref.invalidate(weekTimeBlocksProvider);
    ref.invalidate(countdownsProvider);
    ref.invalidate(recentTimeBlocksProvider);
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.recentBlocks});

  final TimeState state;
  final List<TimeBlock>? recentBlocks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.lg,
          AppSpace.screen,
          96,
        ),
        children: [
          Text('Time', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpace.xs),
          Text(
            AppCopy.timeTagline,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          AvailableTimeCard(state: state),
          SectionHeader(
            title: 'This week',
            trailing: TextButton(
              onPressed: () => BudgetManagerSheet.show(context),
              child: const Text('Edit targets'),
            ),
          ),
          WeeklyTimeBudgetCard(state: state),
          const SizedBox(height: AppSpace.cardGap),
          WeeklyHoursChart(goalWeeklyTarget: state.goalWeeklyTarget),
          SectionHeader(
            title: 'Countdowns',
            trailing: TextButton.icon(
              onPressed: () => CountdownEditor.show(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
            ),
          ),
          CountdownList(countdowns: state.countdowns),
          const SectionHeader(title: 'Logged'),
          TimeBlockHistoryList(
            blocks: recentBlocks ?? state.weekBlocks,
            budgets: state.budgets,
            now: state.now,
          ),
        ],
      ),
    );
  }
}

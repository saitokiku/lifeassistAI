import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/haptics.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../../shared/widgets/status_badge.dart';
import '../application/focus_controller.dart';
import '../application/focus_state.dart';
import '../domain/growth_metric.dart';
import '../domain/growth_metric_entry.dart';
import '../domain/main_goal.dart';
import 'widgets/action_history_list.dart';
import 'widgets/growth_metric_chart.dart';
import 'widgets/action_log_form.dart';
import 'widgets/growth_metric_editor.dart';
import 'widgets/growth_metric_entry_form.dart';
import 'widgets/main_goal_editor.dart';
import 'widgets/metric_history_chart.dart';
import 'widgets/milestone_editor.dart';
import 'widgets/milestone_list.dart';
import 'widgets/relative_date.dart';

/// Focus — the user's main goal: where it stands, the next milestone, the
/// number that proves movement, and the daily step that keeps it alive.
class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusStateProvider);
    final goalAsync = ref.watch(mainGoalProvider);
    final milestonesAsync = ref.watch(milestonesProvider);
    final metricsAsync = ref.watch(growthMetricsProvider);
    final actionsAsync = ref.watch(dailyActionsProvider);
    final activeId = state?.activeMetric?.id;
    final entriesAsync =
        activeId == null ? null : ref.watch(metricEntriesProvider(activeId));

    final hasError = goalAsync.hasError ||
        milestonesAsync.hasError ||
        metricsAsync.hasError ||
        actionsAsync.hasError ||
        (entriesAsync?.hasError ?? false);
    final metrics = metricsAsync.valueOrNull;
    final ready = !hasError && state != null && metrics != null;

    return Scaffold(
      floatingActionButton: !ready || !state.hasGoal
          ? null
          : FloatingActionButton.extended(
              onPressed: () => ActionLogForm.show(
                context,
                action: state.todayAction,
              ),
              icon: Icon(
                state.todayActionLogged
                    ? Icons.edit_outlined
                    : Icons.add_task_rounded,
              ),
              label: Text(
                state.todayActionLogged ? "Edit today's step" : 'Log a step',
              ),
            ),
      body: SafeArea(
        child: hasError
            ? ErrorState(
                onRetry: () {
                  ref.invalidate(mainGoalProvider);
                  ref.invalidate(milestonesProvider);
                  ref.invalidate(growthMetricsProvider);
                  ref.invalidate(dailyActionsProvider);
                  ref.invalidate(metricEntriesProvider);
                },
              )
            : !ready
                ? const SkeletonList()
                : ContentWidth(
                    child: state.hasGoal
                        ? _GoalContent(state: state, metrics: metrics)
                        : const _NoGoalContent(),
                  ),
      ),
    );
  }
}

// --- No goal yet -------------------------------------------------------------

/// The invitation state: explains the idea and offers example goals.
class _NoGoalContent extends StatelessWidget {
  const _NoGoalContent();

  static const _examples = [
    'Finish nursing school',
    'Build my business',
    'Run a marathon',
    'Become debt-free',
    'Publish my novel',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.lg,
        AppSpace.screen,
        AppSpace.xxl,
      ),
      children: [
        Text('Focus', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpace.xs),
        Text(
          'One goal, front and center.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        AppCard(
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you working toward?',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Pick the one outcome that matters most right now. '
                'This tab keeps it in front of you — with milestones, '
                'a progress number if you want one, and one small step '
                'a day.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final example in _examples)
                    ActionChip(
                      label: Text(example),
                      onPressed: () {
                        Haptics.select();
                        MainGoalEditor.show(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              FilledButton(
                onPressed: () => MainGoalEditor.show(context),
                child: const Text('Set your main goal'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Goal set ----------------------------------------------------------------

class _GoalContent extends StatelessWidget {
  const _GoalContent({required this.state, required this.metrics});

  final FocusState state;
  final List<GrowthMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = state.goal!;
    final streak = state.actionStreak;
    final missed = state.missedDaysLast30;
    final showAllMeasures = metrics.length > 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.lg,
        AppSpace.screen,
        96,
      ),
      children: [
        _GoalHeader(state: state),
        if (goal.isCompleted) ...[
          const SizedBox(height: AppSpace.xl),
          _CompletedCard(goal: goal),
        ] else ...[
          const SizedBox(height: AppSpace.md),
          if (goal.isPaused) const _PausedNote(),
          SectionHeader(
            title: 'Milestones',
            trailing: TextButton.icon(
              onPressed: () => MilestoneEditor.show(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ),
          if (state.milestones.isEmpty)
            _InviteCard(
              text: 'Break the goal into a few concrete milestones — '
                  'the next one becomes your direction.',
              actionLabel: 'Add the first milestone',
              onTap: () => MilestoneEditor.show(context),
            )
          else ...[
            if (state.milestones.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Text(
                  '${state.milestonesDone} of ${state.milestones.length} done',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.textTertiary,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ),
            MilestoneList(milestones: state.milestones, today: state.today),
          ],
          SectionHeader(
            title: 'Progress measure',
            trailing: state.activeMetric == null && metrics.isEmpty
                ? null
                : TextButton.icon(
                    onPressed: () => GrowthMetricEditor.show(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
          ),
          if (state.activeMetric case final metric?) ...[
            _ActiveMeasureCard(metric: metric, state: state),
            const SizedBox(height: AppSpace.cardGap),
            MetricCard(
              title: 'Trend',
              child: MetricHistoryChart(
                entries: state.activeMetricEntries,
                unit: metric.unit,
                weeklyTarget: metric.weeklyTarget,
                today: state.today,
              ),
            ),
          ] else
            _InviteCard(
              text: 'Optional: track one number that shows the goal is '
                  'moving — pages written, pounds lost, dollars saved.',
              actionLabel: 'Track a number',
              onTap: () => GrowthMetricEditor.show(context),
            ),
          if (showAllMeasures) ...[
            const SectionHeader(title: 'All measures'),
            for (final metric in metrics)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: _MeasureRow(metric: metric),
              ),
          ],
          const SectionHeader(title: 'Daily steps'),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Streak',
                  value: '$streak ${streak == 1 ? 'day' : 'days'}',
                  caption: 'one step a day',
                  icon: Icons.local_fire_department,
                  level: streak > 0 ? StatusLevel.aligned : StatusLevel.neutral,
                ),
              ),
              const SizedBox(width: AppSpace.cardGap),
              Expanded(
                child: StatTile(
                  label: 'Missed',
                  value: '$missed ${missed == 1 ? 'day' : 'days'}',
                  caption: 'in the last 30 days',
                  icon: Icons.event_busy,
                  level: missed == 0 ? StatusLevel.aligned : StatusLevel.watch,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          ActionHistoryList(actions: state.actions, today: state.today),
        ],
      ],
    );
  }
}

/// Goal title, why, timeframe, and the goal menu.
class _GoalHeader extends ConsumerWidget {
  const _GoalHeader({required this.state});

  final FocusState state;

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final goal = state.goal!;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Mark "${goal.title}" complete?',
      message: 'Milestones and history stay. You can set a new goal after.',
      confirmLabel: 'Complete it',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(focusControllerProvider).completeGoal(goal.id);
    Haptics.medium();
  }

  Future<void> _startNew(BuildContext context, WidgetRef ref) async {
    final goal = state.goal!;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Start a new goal?',
      message: '"${goal.title}" moves to your archive. Its milestones and '
          'history stay on this tab.',
      confirmLabel: 'New goal',
    );
    if (!confirmed || !context.mounted) return;
    await MainGoalEditor.show(context, goal: goal, replacing: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = state.goal!;
    final controller = ref.read(focusControllerProvider);

    final daysLeft = goal.daysLeft(state.today);
    final meta = <String>[
      if (goal.isPaused)
        'Paused'
      else if (daysLeft != null)
        daysLeft >= 0
            ? '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left'
            : '${-daysLeft} ${daysLeft == -1 ? 'day' : 'days'} past target',
      'day ${goal.daysIn(state.today) + 1}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MAIN GOAL',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(goal.title, style: theme.textTheme.headlineSmall),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: scheme.textTertiary),
              tooltip: 'Goal options',
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    await MainGoalEditor.show(context, goal: goal);
                  case 'pause':
                    await controller.pauseGoal(goal.id);
                  case 'resume':
                    await controller.resumeGoal(goal.id);
                  case 'complete':
                    await _complete(context, ref);
                  case 'new':
                    await _startNew(context, ref);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit goal')),
                if (goal.isPaused)
                  const PopupMenuItem(value: 'resume', child: Text('Resume'))
                else
                  const PopupMenuItem(value: 'pause', child: Text('Pause')),
                const PopupMenuItem(
                    value: 'complete', child: Text('Mark complete')),
                const PopupMenuItem(
                    value: 'new', child: Text('Start a new goal')),
              ],
            ),
          ],
        ),
        if (goal.why.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            goal.why,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpace.xs),
        Text(
          meta.join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.textTertiary,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ],
    );
  }
}

/// Quiet note shown while the goal is paused.
class _PausedNote extends StatelessWidget {
  const _PausedNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Row(
        children: [
          Icon(Icons.pause_circle_outline,
              size: 16, color: theme.colorScheme.textTertiary),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              'Paused — no daily pressure until you resume.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Celebration state once the goal is completed.
class _CompletedCard extends ConsumerWidget {
  const _CompletedCard({required this.goal});

  final MainGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppCard(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBadge(label: 'Completed', level: StatusLevel.aligned),
          const SizedBox(height: AppSpace.md),
          Text('You saw it through.', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Everything you logged stays in your history. When you\'re '
            'ready, set the next goal.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          FilledButton(
            onPressed: () => MainGoalEditor.show(context),
            child: const Text('Set a new goal'),
          ),
        ],
      ),
    );
  }
}

/// Compact inline invitation used for empty sections.
class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.text,
    required this.actionLabel,
    required this.onTap,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            actionLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The tracked measure: latest value, 7-day trend, inline logging.
class _ActiveMeasureCard extends StatelessWidget {
  const _ActiveMeasureCard({required this.metric, required this.state});

  final GrowthMetric metric;
  final FocusState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = state.activeMetricEntries.take(7).toList();

    return AppCard(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.textTertiary,
                  ),
                ),
              ),
              const StatusBadge(label: 'Tracking', level: StatusLevel.aligned),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '${Formatters.number(metric.currentValue)} ${metric.unit}',
            style: theme.textTheme.headlineMedium,
          ),
          if (metric.weeklyTarget > 0) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              'Weekly target ${Formatters.number(metric.weeklyTarget)} '
              '${metric.unit}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: 48,
            child: Sparkline(
              values: state.sevenDayTrend,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              FilledButton.tonal(
                onPressed: () =>
                    GrowthMetricEntryForm.show(context, metric: metric),
                child: const Text('Log value'),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Edit measure',
                icon: Icon(Icons.more_horiz, color: scheme.textTertiary),
                onPressed: () =>
                    GrowthMetricEditor.show(context, metric: metric),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            Text(
              'RECENT ENTRIES',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            for (final entry in entries)
              _EntryRow(entry: entry, metric: metric, today: state.today),
          ],
        ],
      ),
    );
  }
}

/// A compact entry row: tap to edit that day, swipe to delete with undo.
class _EntryRow extends ConsumerWidget {
  const _EntryRow({
    required this.entry,
    required this.metric,
    required this.today,
  });

  final GrowthMetricEntry entry;
  final GrowthMetric metric;
  final DateTime today;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(focusControllerProvider);
    final date = AppDateUtils.parseDateKey(entry.date);
    final value = entry.value;
    final note = entry.note;

    await controller.deleteEntry(entry.id);
    Haptics.light();
    if (!context.mounted) return;
    showUndoSnack(
      context,
      'Entry deleted.',
      onUndo: () => controller.upsertEntry(
        metricId: metric.id,
        date: date,
        value: value,
        note: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('entry-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.critical.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          size: 18,
          color: AppColors.critical,
        ),
      ),
      confirmDismiss: (_) async {
        await _delete(context, ref);
        return true;
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: () => GrowthMetricEntryForm.show(
          context,
          metric: metric,
          entry: entry,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  relativeDayLabel(
                    AppDateUtils.parseDateKey(entry.date),
                    today,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${Formatters.number(entry.value)} ${metric.unit}',
                style: theme.textTheme.numberBody,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One measure in the All-measures list. Tap to start tracking it.
class _MeasureRow extends ConsumerWidget {
  const _MeasureRow({required this.metric});

  final GrowthMetric metric;

  Future<void> _activate(BuildContext context, WidgetRef ref) async {
    Haptics.select();
    await ref.read(focusControllerProvider).setActiveMetric(metric.id);
    if (context.mounted) showSuccessSnack(context, 'Now tracking this one.');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete measure?',
      message: 'Deletes "${metric.name}" and every entry logged with it. '
          'No undo on this one.',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(focusControllerProvider).deleteMetric(metric.id);
    if (context.mounted) showSuccessSnack(context, 'Measure deleted.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = metric.isActive;

    return AppCard(
      tinted: active,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
      ),
      onTap: active ? null : () => _activate(context, ref),
      child: Row(
        children: [
          Icon(
            active ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
            color: active ? AppColors.primary : scheme.textTertiary,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Latest ${Formatters.number(metric.currentValue)} '
                  '${metric.unit}'
                  '${metric.weeklyTarget > 0 ? ' · target ${Formatters.number(metric.weeklyTarget)} a week' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, size: 20, color: scheme.textTertiary),
            tooltip: 'More',
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  await GrowthMetricEditor.show(context, metric: metric);
                case 'delete':
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
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
import '../application/kaizen_controller.dart';
import '../application/kaizen_state.dart';
import '../domain/growth_metric.dart';
import '../domain/growth_metric_entry.dart';
import 'widgets/build_hunt_warning_card.dart';
import 'widgets/experiment_history_list.dart';
import 'widgets/experiment_log_form.dart';
import 'widgets/growth_metric_chart.dart';
import 'widgets/growth_metric_editor.dart';
import 'widgets/growth_metric_entry_form.dart';
import 'widgets/metric_history_chart.dart';
import 'widgets/relative_date.dart';

/// Kaizen — the growth engine. One hunt (the active metric) up top, the
/// daily kill-or-confirm experiment ritual below.
class KaizenScreen extends ConsumerWidget {
  const KaizenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kaizenStateProvider);
    final metricsAsync = ref.watch(growthMetricsProvider);
    final activeAsync = ref.watch(activeMetricProvider);
    final experimentsAsync = ref.watch(experimentsProvider);
    final activeId = state?.activeMetric?.id;
    final entriesAsync =
        activeId == null ? null : ref.watch(metricEntriesProvider(activeId));

    final hasError = metricsAsync.hasError ||
        activeAsync.hasError ||
        experimentsAsync.hasError ||
        (entriesAsync?.hasError ?? false);
    final metrics = metricsAsync.valueOrNull;
    final ready = !hasError && state != null && metrics != null;

    return Scaffold(
      floatingActionButton: !ready
          ? null
          : FloatingActionButton.extended(
              onPressed: () => ExperimentLogForm.show(
                context,
                experiment: state.todayExperiment,
              ),
              icon: Icon(
                state.todayExperimentLogged
                    ? Icons.edit_outlined
                    : Icons.science_outlined,
              ),
              label: Text(
                state.todayExperimentLogged
                    ? "Edit today's verdict"
                    : 'Log experiment',
              ),
            ),
      body: SafeArea(
        child: hasError
            ? ErrorState(
                onRetry: () {
                  ref.invalidate(growthMetricsProvider);
                  ref.invalidate(activeMetricProvider);
                  ref.invalidate(experimentsProvider);
                  ref.invalidate(metricEntriesProvider);
                },
              )
            : state == null || metrics == null
                ? const SkeletonList()
                : ContentWidth(
                    child: _KaizenContent(state: state, metrics: metrics),
                  ),
      ),
    );
  }
}

class _KaizenContent extends StatelessWidget {
  const _KaizenContent({required this.state, required this.metrics});

  final KaizenState state;
  final List<GrowthMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streak = state.experimentStreak;
    final missed = state.missedDaysLast30;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen, AppSpace.lg, AppSpace.screen, 96,
      ),
      children: [
        Text('Kaizen', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpace.xs),
        Text(
          'One hunt. One test a day.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        const BuildHuntWarningCard(),
        const SizedBox(height: AppSpace.xl),
        if (state.activeMetric case final metric?) ...[
          _ActiveMetricCard(metric: metric, state: state),
          const SizedBox(height: AppSpace.cardGap),
          MetricCard(
            title: 'Metric trend',
            child: MetricHistoryChart(
              entries: state.activeMetricEntries,
              unit: metric.unit,
              weeklyTarget: metric.weeklyTarget,
              today: state.today,
            ),
          ),
        ] else
          const _NoHuntCard(),
        if (metrics.isNotEmpty) ...[
          SectionHeader(
            title: 'All metrics',
            trailing: TextButton.icon(
              onPressed: () => GrowthMetricEditor.show(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
            ),
          ),
          for (final metric in metrics)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _MetricRow(metric: metric),
            ),
        ],
        const SectionHeader(title: 'Experiments'),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Streak',
                value: '$streak ${streak == 1 ? 'day' : 'days'}',
                caption: 'one test a day',
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
        ExperimentHistoryList(
          experiments: state.experiments,
          today: state.today,
        ),
      ],
    );
  }
}

/// The hero: the one number the engine is pointed at.
class _ActiveMetricCard extends StatelessWidget {
  const _ActiveMetricCard({required this.metric, required this.state});

  final GrowthMetric metric;
  final KaizenState state;

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
              const StatusBadge(label: 'Hunt', level: StatusLevel.aligned),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '${Formatters.number(metric.currentValue)} ${metric.unit}',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Weekly target ${Formatters.number(metric.weeklyTarget)} '
            '${metric.unit}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
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
                tooltip: 'Edit metric',
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
    final controller = ref.read(kaizenControllerProvider);
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

/// Gentle setup prompt when nothing is the hunt yet.
class _NoHuntCard extends StatelessWidget {
  const _NoHuntCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No active hunt', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'One number that proves growth. ${AppCopy.oneHunt}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => GrowthMetricEditor.show(context),
              child: const Text('Create metric'),
            ),
          ),
        ],
      ),
    );
  }
}

/// One metric in the All-metrics list. Tap to make it the hunt.
class _MetricRow extends ConsumerWidget {
  const _MetricRow({required this.metric});

  final GrowthMetric metric;

  Future<void> _activate(BuildContext context, WidgetRef ref) async {
    Haptics.select();
    await ref.read(kaizenControllerProvider).setActiveMetric(metric.id);
    if (context.mounted) showSuccessSnack(context, 'Hunt switched.');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete metric?',
      message: 'Deletes "${metric.name}" and every entry logged with it. '
          'No undo on this one.',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(kaizenControllerProvider).deleteMetric(metric.id);
    if (context.mounted) showSuccessSnack(context, 'Metric deleted.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = metric.isActive;

    return AppCard(
      tinted: active,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg, AppSpace.md, AppSpace.xs, AppSpace.md,
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
                  '${metric.unit} · target '
                  '${Formatters.number(metric.weeklyTarget)} a week',
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

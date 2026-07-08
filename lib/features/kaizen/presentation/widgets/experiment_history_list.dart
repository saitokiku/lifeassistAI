import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/kaizen_controller.dart';
import '../../domain/daily_experiment.dart';
import 'experiment_log_form.dart';
import 'relative_date.dart';

/// Experiment history: verdict filter chips, then one row per verdict.
/// Tap edits; swipe deletes with undo. Filters get their own empty copy.
class ExperimentHistoryList extends ConsumerStatefulWidget {
  const ExperimentHistoryList({
    super.key,
    required this.experiments,
    this.today,
  });

  final List<DailyExperiment> experiments;

  /// The app's ticking "today"; falls back to the device clock.
  final DateTime? today;

  @override
  ConsumerState<ExperimentHistoryList> createState() =>
      _ExperimentHistoryListState();
}

class _ExperimentHistoryListState extends ConsumerState<ExperimentHistoryList> {
  ExperimentVerdict? _filter;

  void _setFilter(ExperimentVerdict? value) {
    Haptics.select();
    setState(() => _filter = value);
  }

  Future<void> _edit(DailyExperiment experiment) =>
      ExperimentLogForm.show(context, experiment: experiment);

  /// Delete with a working undo: re-logs the captured row via logExperiment.
  Future<void> _delete(DailyExperiment experiment) async {
    final controller = ref.read(kaizenControllerProvider);
    final date = AppDateUtils.parseDateKey(experiment.date);
    final hypothesis = experiment.hypothesis;
    final actionTaken = experiment.actionTaken;
    final result = experiment.result;
    final verdict = experiment.verdict;
    final notes = experiment.notes;

    await controller.deleteExperiment(experiment.id);
    Haptics.light();
    if (!mounted) return;
    showUndoSnack(
      context,
      'Experiment deleted.',
      onUndo: () => controller.logExperiment(
        date: date,
        hypothesis: hypothesis,
        actionTaken: actionTaken,
        result: result,
        verdict: verdict,
        notes: notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.today ??
        ref.watch(kaizenStateProvider)?.today ??
        AppDateUtils.dateOnly(DateTime.now());

    final filtered = _filter == null
        ? widget.experiments
        : [
            for (final e in widget.experiments)
              if (e.verdictEnum == _filter) e,
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _filter == null,
              onSelected: (_) => _setFilter(null),
            ),
            for (final v in ExperimentVerdict.values)
              FilterChip(
                label: Text(v.label),
                selected: _filter == v,
                onSelected: (_) => _setFilter(v),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        if (widget.experiments.isEmpty)
          const EmptyState(
            icon: Icons.science_outlined,
            title: 'No experiments yet',
            message: 'One test. One verdict. Log the first one.',
          )
        else if (filtered.isEmpty)
          EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: 'No ${_filter!.label.toLowerCase()} verdicts yet.',
            actionLabel: 'Clear filter',
            onAction: () => _setFilter(null),
          )
        else
          for (final experiment in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _ExperimentRow(
                experiment: experiment,
                today: today,
                onEdit: () => _edit(experiment),
                onDelete: () => _delete(experiment),
              ),
            ),
      ],
    );
  }
}

class _ExperimentRow extends StatelessWidget {
  const _ExperimentRow({
    required this.experiment,
    required this.today,
    required this.onEdit,
    required this.onDelete,
  });

  final DailyExperiment experiment;
  final DateTime today;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final verdict = experiment.verdictEnum;
    final when = relativeDayLabel(
      AppDateUtils.parseDateKey(experiment.date),
      today,
    );

    return Dismissible(
      key: ValueKey('experiment-${experiment.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.xl),
        decoration: BoxDecoration(
          color: AppColors.critical.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.critical,
        ),
      ),
      confirmDismiss: (_) async {
        await onDelete();
        return true;
      },
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.xs, AppSpace.md,
        ),
        onTap: onEdit,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: verdict.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experiment.hypothesis,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${verdict.label} · $when',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                size: 20,
                color: scheme.textTertiary,
              ),
              tooltip: 'More',
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
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

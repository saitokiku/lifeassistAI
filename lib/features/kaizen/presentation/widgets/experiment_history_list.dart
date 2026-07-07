import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/kaizen_controller.dart';
import '../../domain/daily_experiment.dart';
import 'experiment_log_form.dart';

/// Experiment history with verdict filter, edit, and delete.
class ExperimentHistoryList extends ConsumerStatefulWidget {
  const ExperimentHistoryList({super.key, required this.experiments});

  final List<DailyExperiment> experiments;

  @override
  ConsumerState<ExperimentHistoryList> createState() =>
      _ExperimentHistoryListState();
}

class _ExperimentHistoryListState extends ConsumerState<ExperimentHistoryList> {
  ExperimentVerdict? _filter;

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null
        ? widget.experiments
        : widget.experiments
            .where((e) => e.verdictEnum == _filter)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final v in ExperimentVerdict.values)
              FilterChip(
                label: Text(v.label),
                selected: _filter == v,
                onSelected: (_) => setState(() => _filter = v),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.science_outlined,
            title: 'No experiments here',
            message: 'One test. One verdict. Log the first one.',
          )
        else
          for (final experiment in filtered)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(experiment.hypothesis,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${experiment.actionTaken} → ${experiment.result}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StatusBadge(
                            label: experiment.verdictEnum.label,
                            level: switch (experiment.verdictEnum) {
                              ExperimentVerdict.confirm => StatusLevel.aligned,
                              ExperimentVerdict.iterate => StatusLevel.watch,
                              ExperimentVerdict.kill => StatusLevel.critical,
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(Formatters.shortDate(
                              AppDateUtils.parseDateKey(experiment.date))),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await ExperimentLogForm.show(context,
                          experiment: experiment);
                    } else if (value == 'delete') {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Delete experiment?',
                        message: 'This removes the verdict for this day.',
                      );
                      if (confirmed) {
                        await ref
                            .read(kaizenControllerProvider)
                            .deleteExperiment(experiment.id);
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

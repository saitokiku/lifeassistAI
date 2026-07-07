import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/kaizen_controller.dart';
import 'widgets/build_hunt_warning_card.dart';
import 'widgets/experiment_history_list.dart';
import 'widgets/experiment_log_form.dart';
import 'widgets/growth_metric_chart.dart';
import 'widgets/growth_metric_editor.dart';
import 'widgets/growth_metric_entry_form.dart';

/// Kaizen module: growth metrics and daily kill-or-confirm experiments.
class KaizenScreen extends ConsumerWidget {
  const KaizenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kaizenStateProvider);
    final metrics = ref.watch(growthMetricsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Kaizen')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ExperimentLogForm.show(context),
        icon: const Icon(Icons.science_outlined),
        label: const Text('Log experiment'),
      ),
      body: state == null || metrics == null
          ? const LoadingView()
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  const BuildHuntWarningCard(),
                  const SizedBox(height: 12),

                  // Active metric card
                  if (state.activeMetric case final metric?) ...[
                    MetricCard(
                      title: 'Active metric · ${metric.name}',
                      badgeLabel: 'Hunt',
                      badgeLevel: StatusLevel.aligned,
                      bigValue:
                          '${Formatters.number(metric.currentValue)} ${metric.unit}',
                      supportText:
                          'Weekly target ${Formatters.number(metric.weeklyTarget)} ${metric.unit}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 56,
                            child: Sparkline(
                              values: state.sevenDayTrend,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              FilledButton.tonal(
                                onPressed: () => GrowthMetricEntryForm.show(
                                    context,
                                    metric: metric),
                                child: const Text("Add today's value"),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => GrowthMetricEditor.show(
                                    context,
                                    metric: metric),
                                child: const Text('Edit metric'),
                              ),
                            ],
                          ),
                          if (state.activeMetricEntries.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            for (final entry
                                in state.activeMetricEntries.take(7))
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.date,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  Text(
                                    '${Formatters.number(entry.value)} ${metric.unit}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.close, size: 14),
                                    tooltip: 'Delete entry',
                                    onPressed: () async {
                                      final confirmed = await showConfirmDialog(
                                        context,
                                        title: 'Delete entry?',
                                        message:
                                            'Removes the ${entry.date} value.',
                                      );
                                      if (confirmed) {
                                        await ref
                                            .read(kaizenControllerProvider)
                                            .deleteEntry(entry.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  ] else
                    MetricCard(
                      title: 'Active metric',
                      supportText:
                          'No active metric. ${AppCopy.oneHunt}',
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton(
                          onPressed: () => GrowthMetricEditor.show(context),
                          child: const Text('Create metric'),
                        ),
                      ),
                    ),

                  SectionHeader(
                    title: 'All metrics',
                    trailing: TextButton.icon(
                      onPressed: () => GrowthMetricEditor.show(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New'),
                    ),
                  ),
                  for (final metric in metrics)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(metric.name),
                        subtitle: Text(
                            '${Formatters.number(metric.currentValue)} ${metric.unit} · target ${Formatters.number(metric.weeklyTarget)}/wk'),
                        leading: metric.isActive
                            ? const Icon(Icons.gps_fixed,
                                color: AppColors.primary)
                            : const Icon(Icons.gps_not_fixed),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            final controller =
                                ref.read(kaizenControllerProvider);
                            if (value == 'activate') {
                              await controller.setActiveMetric(metric.id);
                            } else if (value == 'edit') {
                              await GrowthMetricEditor.show(context,
                                  metric: metric);
                            } else if (value == 'delete') {
                              final confirmed = await showConfirmDialog(
                                context,
                                title: 'Delete metric?',
                                message:
                                    'Deletes "${metric.name}" and all its entries.',
                              );
                              if (confirmed) {
                                await controller.deleteMetric(metric.id);
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            if (!metric.isActive)
                              const PopupMenuItem(
                                  value: 'activate',
                                  child: Text('Make active')),
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    ),

                  SectionHeader(
                    title:
                        'Experiments · ${state.experimentStreak}-day streak · ${state.missedDaysLast30} missed in 30d',
                  ),
                  ExperimentHistoryList(experiments: state.experiments),
                ],
              ),
            ),
    );
  }
}

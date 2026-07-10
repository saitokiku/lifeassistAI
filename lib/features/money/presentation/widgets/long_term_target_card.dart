import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../../identity/application/identity_controller.dart';
import '../../../identity/domain/freedom_target.dart';
import 'long_term_target_editor.dart';
import '../../../../shared/widgets/quick_update_sheet.dart';

/// The long-term target: optional passive-income and net-worth marks to
/// aim at over years. Each progress row is tappable — one tap, one field.
class LongTermTargetCard extends ConsumerWidget {
  const LongTermTargetCard({super.key, required this.target});

  final FreedomTarget? target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = target;
    if (t == null) return _EmptyTargetCard(theme: theme);

    final description = t.description?.trim();
    final deadlineKey = t.targetDate;
    final deadline = (deadlineKey == null || deadlineKey.isEmpty)
        ? null
        : AppDateUtils.parseDateKey(deadlineKey);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.cardPadding,
        AppSpace.cardPadding,
        AppSpace.sm,
        AppSpace.cardPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: theme.textTheme.titleMedium),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (deadline != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'By ${Formatters.fullDate(deadline)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: theme.colorScheme.textTertiary,
                ),
                onSelected: (value) async {
                  if (value == 'edit') {
                    await LongTermTargetEditor.show(context, target: t);
                  } else if (value == 'delete') {
                    final controller = ref.read(identityControllerProvider);
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Delete this target?',
                      message:
                          'Removes "${t.title}" and both progress lines. '
                          'You can set a new target anytime.',
                    );
                    if (confirmed) {
                      await controller.deleteFreedomTarget(t.id);
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
          const SizedBox(height: AppSpace.md),
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProgressRow(
                  label: 'Passive income',
                  values:
                      '${Formatters.money(t.currentMonthlyPassiveIncome)} of ${Formatters.money(t.targetMonthlyPassiveIncome)}/mo',
                  progress: t.passiveIncomeProgress,
                  color: AppColors.primary,
                  onTap: () => _updatePassiveIncome(context, ref, t),
                ),
                const SizedBox(height: AppSpace.xs),
                _ProgressRow(
                  label: 'Liquid net worth',
                  values:
                      '${Formatters.money(t.currentLiquidNetWorth)} of ${Formatters.money(t.targetLiquidNetWorth)}',
                  progress: t.netWorthProgress,
                  color: AppColors.aligned,
                  onTap: () => _updateNetWorth(context, ref, t),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePassiveIncome(
      BuildContext context, WidgetRef ref, FreedomTarget t) {
    final controller = ref.read(identityControllerProvider);
    return QuickUpdateSheet.show(
      context,
      title: 'Passive income',
      subtitle:
          'Target ${Formatters.money(t.targetMonthlyPassiveIncome)}/mo.',
      label: 'Current monthly passive income',
      suffixText: '/mo',
      initialValue: t.currentMonthlyPassiveIncome,
      validator: (v) => Validators.nonNegativeNumber(v, label: 'Current'),
      onSave: (value) => controller.updateFreedomTarget(
        t.copyWith(currentMonthlyPassiveIncome: value),
      ),
    );
  }

  Future<void> _updateNetWorth(
      BuildContext context, WidgetRef ref, FreedomTarget t) {
    final controller = ref.read(identityControllerProvider);
    return QuickUpdateSheet.show(
      context,
      title: 'Liquid net worth',
      subtitle: 'Target ${Formatters.money(t.targetLiquidNetWorth)}.',
      label: 'Current liquid net worth',
      initialValue: t.currentLiquidNetWorth,
      validator: (v) => Validators.nonNegativeNumber(v, label: 'Current'),
      onSave: (value) => controller.updateFreedomTarget(
        t.copyWith(currentLiquidNetWorth: value),
      ),
    );
  }
}

/// One tappable progress line: label, tabular values, animated bar.
class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.values,
    required this.progress,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String values;
  final double progress;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  values,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: theme.colorScheme.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            LabeledProgressBar(progress: progress, color: color),
          ],
        ),
      ),
    );
  }
}

/// Designed empty state: what the target is for, and the first move.
class _EmptyTargetCard extends StatelessWidget {
  const _EmptyTargetCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.chip + 2),
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where is all this heading?',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optional: set passive-income and net-worth marks '
                      'to aim at over the years.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => LongTermTargetEditor.show(context),
              child: const Text('Set target'),
            ),
          ),
        ],
      ),
    );
  }
}

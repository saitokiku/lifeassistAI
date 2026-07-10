import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/time_controller.dart';
import '../../domain/time_category.dart';
import 'time_budget_editor.dart';
import 'time_kind_icon.dart';

/// Manage weekly categories and targets. Watches the budgets stream so
/// edits, creates, and deletes appear live while the sheet is open.
class BudgetManagerSheet extends ConsumerWidget {
  const BudgetManagerSheet({super.key});

  static Future<void> show(BuildContext context) => showAppSheet<void>(
        context,
        builder: (_) => const BudgetManagerSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final budgetsAsync = ref.watch(timeBudgetsProvider);

    return AppSheet(
      title: 'Weekly targets',
      subtitle: 'Tap a category to edit it. Targets are the plan — '
          'logged hours are the score.',
      footer: FilledButton(
        onPressed: () => TimeBudgetEditor.show(context),
        child: const Text('New category'),
      ),
      children: [
        budgetsAsync.when(
          data: (budgets) => budgets.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                  child: Text(
                    'No categories yet. Create one below to start '
                    'pointing hours somewhere.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final budget in budgets) _BudgetRow(budget: budget),
                  ],
                ),
          loading: () => const Column(
            children: [
              SkeletonCard(height: 56),
              SizedBox(height: AppSpace.sm),
              SkeletonCard(height: 56),
              SizedBox(height: AppSpace.sm),
              SkeletonCard(height: 56),
            ],
          ),
          error: (_, __) => ErrorState(
            title: "Couldn't load categories.",
            onRetry: () => ref.invalidate(timeBudgetsProvider),
          ),
        ),
      ],
    );
  }
}

class _BudgetRow extends ConsumerWidget {
  const _BudgetRow({required this.budget});

  final TimeBudget budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final kind = TimeCategoryKind.parse(budget.kind);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      onTap: () => TimeBudgetEditor.show(context, budget: budget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xs,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            Icon(kind.icon,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.hours(budget.weeklyTargetHours)} a week · '
                    'counts as ${kind.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: theme.colorScheme.textTertiary,
              tooltip: 'Delete',
              onPressed: () => _delete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(timeControllerProvider);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${budget.name}?',
      message: 'Every hour ever logged against it goes too. '
          'That history cannot be recovered.',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await controller.deleteBudget(budget.id);
    } catch (_) {
      if (context.mounted) {
        showErrorSnack(context, "That didn't delete. Try again.");
      }
      return;
    }
    if (context.mounted) showSuccessSnack(context, 'Deleted.');
  }
}

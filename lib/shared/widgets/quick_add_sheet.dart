import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'app_sheet.dart';

/// What the user wants to capture, chosen from the quick-add sheet.
enum QuickAddAction { timeBlock, transaction, metricValue, goalStep, idea }

/// Global quick capture: one sheet, one-tap destinations.
/// Returns the chosen action; the caller opens the matching form so the
/// capture flow always runs on a live screen context. Pass [actions] to
/// show only what applies right now (e.g. no metric → no metric tile).
Future<QuickAddAction?> showQuickAddSheet(
  BuildContext context, {
  List<QuickAddAction> actions = QuickAddAction.values,
}) {
  return showAppSheet<QuickAddAction>(
    context,
    builder: (sheetContext) => AppSheet(
      title: 'Quick add',
      subtitle: 'Get it out of your head and into the app.',
      children: [
        _ActionGrid(
          actions: actions,
          onPick: (action) => Navigator.of(sheetContext).pop(action),
        ),
      ],
    ),
  );
}

class _ActionGrid extends ConsumerWidget {
  const _ActionGrid({required this.actions, required this.onPick});

  final List<QuickAddAction> actions;
  final ValueChanged<QuickAddAction> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const all = [
      (QuickAddAction.goalStep, Icons.add_task_rounded, 'Goal step'),
      (QuickAddAction.transaction, Icons.receipt_long_outlined, 'Add expense'),
      (QuickAddAction.timeBlock, Icons.schedule_outlined, 'Log time'),
      (QuickAddAction.metricValue, Icons.trending_up, 'Measure value'),
      (QuickAddAction.idea, Icons.lightbulb_outline, 'Park an idea'),
    ];
    final items = [
      for (final item in all)
        if (actions.contains(item.$1)) item,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpace.md;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (action, icon, label) in items)
              SizedBox(
                width: width,
                child: _ActionTile(
                  icon: icon,
                  label: label,
                  onTap: () => onPick(action),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        side: BorderSide(color: scheme.outlineFaint),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.lg,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(label, style: theme.textTheme.labelLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

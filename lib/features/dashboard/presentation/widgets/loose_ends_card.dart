import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../application/dashboard_state.dart';

/// Things quietly waiting on a decision. Renders nothing when life is tidy.
class LooseEndsCard extends StatelessWidget {
  const LooseEndsCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final ideasDue = state.ideasDueForReview;
    final uncategorized = state.money.snapshot.uncategorizedCount;

    final rows = <Widget>[
      if (ideasDue > 0)
        _LooseEndRow(
          icon: Icons.lightbulb_outline,
          text:
              '$ideasDue idea${ideasDue == 1 ? '' : 's'} finished cooling — give a verdict',
          route: '/ideas',
        ),
      if (uncategorized > 0)
        _LooseEndRow(
          icon: Icons.help_outline,
          text:
              '$uncategorized uncategorized transaction${uncategorized == 1 ? '' : 's'} fogging the scoreboard',
          route: '/money',
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.sectionGap, bottom: 10),
          child: Text(
            'LOOSE ENDS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.textTertiary,
                ),
          ),
        ),
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.sm),
          row,
        ],
      ],
    );
  }
}

class _LooseEndRow extends StatelessWidget {
  const _LooseEndRow({
    required this.icon,
    required this.text,
    required this.route,
  });

  final IconData icon;
  final String text;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => context.go(route),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.watch.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(icon, size: 18, color: AppColors.watch),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: theme.colorScheme.textTertiary,
          ),
        ],
      ),
    );
  }
}

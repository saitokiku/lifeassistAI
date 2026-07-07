import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/dashboard_state.dart';

/// Today's Command: four directives generated from live state.
class TodayCommandCard extends StatelessWidget {
  const TodayCommandCard({super.key, required this.command});

  final TodayCommand command;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TODAY'S COMMAND",
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _line(theme, Icons.trending_up, command.kaizenAction),
            _line(theme, Icons.account_balance_outlined, command.moneyConstraint),
            _line(theme, Icons.self_improvement, command.recoveryAction),
            _line(theme, Icons.filter_center_focus, command.antiDiffusionReminder),
          ],
        ),
      ),
    );
  }

  Widget _line(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

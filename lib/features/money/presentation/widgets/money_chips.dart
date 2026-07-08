import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/budget_category.dart';

/// Human label for a category's flag rule, or null when there is none.
String? flagRuleChipLabel(BudgetFlagType type, double monthlyTarget) =>
    switch (type) {
      BudgetFlagType.none => null,
      BudgetFlagType.warnOverTarget =>
        'warn over ${Formatters.money(monthlyTarget)}',
      BudgetFlagType.warnOverZero => r'warn over $0',
      BudgetFlagType.warnOverZeroUnlessIntentional => 'warn unless intentional',
      BudgetFlagType.criticalOverZero => r'critical over $0',
    };

/// Whether a rule chip should carry the critical tint.
bool flagRuleIsCritical(BudgetFlagType type) =>
    type == BudgetFlagType.criticalOverZero;

/// Small quiet chip for metadata: category names, rule summaries.
class MoneyChip extends StatelessWidget {
  const MoneyChip({super.key, required this.label, this.color});

  final String label;

  /// Tint color; defaults to a neutral treatment.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tint?.withValues(alpha: 0.12) ?? theme.colorScheme.elevated,
        borderRadius: BorderRadius.circular(AppRadius.chip - 2),
        border: tint == null
            ? Border.all(color: theme.colorScheme.outlineFaint)
            : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          fontSize: 11,
          height: 15 / 11,
          color: tint ?? theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

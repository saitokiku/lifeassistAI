import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/money_flag.dart';
import 'category_detail_sheet.dart';

/// Leak flags as actionable rows. A flag tied to a category (or the
/// uncategorized bucket) opens the detail sheet — the fix is one tap away.
/// When everything is on pace, one quiet aligned row says so.
class MoneyFlagsCard extends StatelessWidget {
  const MoneyFlagsCard({super.key, required this.flags});

  final List<MoneyFlag> flags;

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) {
      return const _FlagRow(
        icon: Icons.check_circle_outline,
        color: AppColors.aligned,
        message: 'No leaks. Spending is on pace.',
      );
    }

    return Column(
      children: [
        for (final (i, flag) in flags.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.sm),
          _FlagRow(
            icon: flag.severity == MoneyFlagSeverity.critical
                ? Icons.error_outline
                : Icons.warning_amber_outlined,
            color: flag.status.color,
            message: flag.message,
            onTap: _actionFor(context, flag),
          ),
        ],
      ],
    );
  }

  /// Category flags open that category; the uncategorized flag opens the
  /// uncategorized bucket. Surplus flags are information — no fake tap.
  VoidCallback? _actionFor(BuildContext context, MoneyFlag flag) {
    if (flag.categoryId != null) {
      return () =>
          CategoryDetailSheet.show(context, categoryId: flag.categoryId);
    }
    if (flag.kind == MoneyFlagKind.uncategorized) {
      return () => CategoryDetailSheet.show(context);
    }
    return null;
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({
    required this.icon,
    required this.color,
    required this.message,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
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
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(message, style: theme.textTheme.bodyMedium),
          ),
          if (onTap != null)
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

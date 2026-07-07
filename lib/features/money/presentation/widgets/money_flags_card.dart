import 'package:flutter/material.dart';

import '../../../../shared/widgets/metric_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/money_flag.dart';

/// Leak flags and zero-category violations.
class MoneyFlagsCard extends StatelessWidget {
  const MoneyFlagsCard({super.key, required this.flags});

  final List<MoneyFlag> flags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (flags.isEmpty) {
      return MetricCard(
        title: 'Flags',
        badgeLabel: 'Clear',
        badgeLevel: StatusLevel.aligned,
        supportText: 'No leaks. Surplus must move toward freedom.',
      );
    }
    return MetricCard(
      title: 'Flags',
      badgeLabel: flags.any((f) => f.severity == MoneyFlagSeverity.critical)
          ? 'Critical'
          : 'Watch',
      badgeLevel: flags.any((f) => f.severity == MoneyFlagSeverity.critical)
          ? StatusLevel.critical
          : StatusLevel.watch,
      child: Column(
        children: [
          for (final flag in flags)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    flag.severity == MoneyFlagSeverity.critical
                        ? Icons.error_outline
                        : Icons.warning_amber_outlined,
                    size: 16,
                    color: flag.status.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(flag.message, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

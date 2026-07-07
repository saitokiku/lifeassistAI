import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'status_badge.dart';

/// Standard dashboard card: title row (+ badge), a big number, support text,
/// and an arbitrary body below.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    this.badgeLabel,
    this.badgeLevel,
    this.bigValue,
    this.supportText,
    this.child,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String? badgeLabel;
  final StatusLevel? badgeLevel;
  final String? bigValue;
  final String? supportText;
  final Widget? child;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (badgeLabel != null && badgeLevel != null)
                    StatusBadge(label: badgeLabel!, level: badgeLevel!),
                  if (trailing != null) trailing!,
                ],
              ),
              if (bigValue != null) ...[
                const SizedBox(height: 8),
                Text(
                  bigValue!,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              if (supportText != null) ...[
                const SizedBox(height: 4),
                Text(
                  supportText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (child != null) ...[
                const SizedBox(height: 12),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

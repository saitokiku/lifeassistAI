import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'app_card.dart';
import 'status_badge.dart';

/// Standard content card: title row (+ badge), a big number, support text,
/// and an arbitrary body below. Tappable cards show a quiet chevron so the
/// affordance is visible, not guessed.
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
    this.tinted = false,
  });

  final String title;
  final String? badgeLabel;
  final StatusLevel? badgeLevel;
  final String? bigValue;
  final String? supportText;
  final Widget? child;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      tinted: tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (badgeLabel != null && badgeLevel != null) ...[
                const SizedBox(width: AppSpace.sm),
                StatusBadge(label: badgeLabel!, level: badgeLevel!),
              ],
              if (trailing != null) trailing!,
              if (onTap != null && trailing == null) ...[
                const SizedBox(width: AppSpace.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.textTertiary,
                ),
              ],
            ],
          ),
          if (bigValue != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(bigValue!, style: theme.textTheme.headlineMedium),
          ],
          if (supportText != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              supportText!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: AppSpace.md),
            child!,
          ],
        ],
      ),
    );
  }
}

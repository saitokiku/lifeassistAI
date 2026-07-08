import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'app_card.dart';
import 'progress_bar_card.dart';

/// Compact metric tile for 2-column scoreboard grids.
///
/// Overline label, display value, optional caption, optional status dot
/// and mini progress bar. Designed to be scanned in under a second.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.level,
    this.progress,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;

  /// Colors the status dot; also colors the progress fill when set.
  final StatusLevel? level;

  /// 0..1 mini progress bar under the value.
  final double? progress;

  /// Small leading glyph next to the label.
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.tilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: scheme.textTertiary),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.textTertiary,
                  ),
                ),
              ),
              if (level != null)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: level!.color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.numberMedium),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: AppSpace.sm),
            LabeledProgressBar(
              progress: progress!,
              color: (level ?? StatusLevel.neutral).color,
              height: 4,
            ),
          ],
        ],
      ),
    );
  }
}

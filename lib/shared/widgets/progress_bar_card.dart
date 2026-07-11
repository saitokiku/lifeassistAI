import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_card.dart';

/// Thin labeled progress bar used inside cards and lists.
/// The fill animates on change; values above 1 fill the bar.
class LabeledProgressBar extends StatelessWidget {
  const LabeledProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.leading,
    this.trailing,
    this.height = 6,
  });

  /// 0..1; values above 1 fill the bar.
  final double progress;
  final Color color;
  final String? leading;
  final String? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null || trailing != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                if (leading != null)
                  Expanded(
                    child: Text(leading!, style: theme.textTheme.bodySmall),
                  ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: clamped, end: clamped),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.sweep,
            curve: AppMotion.easeOut,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: height,
              color: color,
              backgroundColor: theme.colorScheme.outlineVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// A full card wrapping a titled progress bar.
class ProgressBarCard extends StatelessWidget {
  const ProgressBarCard({
    super.key,
    required this.title,
    required this.progress,
    required this.color,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final double progress;
  final Color color;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          LabeledProgressBar(
            progress: progress,
            color: color,
            trailing: trailing,
          ),
        ],
      ),
    );
  }
}

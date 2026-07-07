import 'package:flutter/material.dart';

/// Thin labeled progress bar used inside cards and lists.
class LabeledProgressBar extends StatelessWidget {
  const LabeledProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.leading,
    this.trailing,
    this.height = 8,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null || trailing != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
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
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: height,
            color: color,
            backgroundColor: theme.colorScheme.outlineVariant,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 10),
            LabeledProgressBar(
              progress: progress,
              color: color,
              trailing: trailing,
            ),
          ],
        ),
      ),
    );
  }
}

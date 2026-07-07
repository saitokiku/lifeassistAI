import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/life_philosophy.dart';

/// The triad, always visible on the identity screen.
class PhilosophyCard extends StatelessWidget {
  const PhilosophyCard({super.key, required this.philosophyText});

  final String philosophyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in LifePhilosophy.triad)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(line, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              philosophyText,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

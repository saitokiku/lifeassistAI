import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "Life Dashboard" + the triad line.
class PhilosophyHeader extends StatelessWidget {
  const PhilosophyHeader({super.key, required this.philosophyText});

  final String philosophyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Life Dashboard', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          philosophyText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

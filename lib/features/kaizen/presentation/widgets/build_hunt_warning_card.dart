import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Fence reminder: growth mode before build mode.
class BuildHuntWarningCard extends StatelessWidget {
  const BuildHuntWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.fence, size: 18, color: AppColors.watch),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${AppCopy.growthHuntFirst} ${AppCopy.buildHuntFenced}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

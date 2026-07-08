import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// One quiet line, not a card: growth mode before build mode.
class BuildHuntWarningCard extends StatelessWidget {
  const BuildHuntWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      child: Row(
        children: [
          const Icon(Icons.fence, size: 16, color: AppColors.watch),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              '${AppCopy.growthHuntFirst} ${AppCopy.buildHuntFenced}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../application/focus_controller.dart';
import '../../domain/main_goal.dart';

/// Past chapters: every main goal ever set, newest first. History is kept,
/// not graded — a shelved goal is a decision, not a failure.
class ChaptersSheet extends ConsumerWidget {
  const ChaptersSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showAppSheet<void>(context, builder: (_) => const ChaptersSheet());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goals = ref.watch(allGoalsProvider).valueOrNull ?? const [];

    return AppSheet(
      title: 'Chapters',
      subtitle: 'Every goal this app has organized itself around.',
      children: [
        if (goals.isEmpty)
          Text(
            'No chapters yet — the first one starts when you set a goal.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          for (final (i, goal) in goals.indexed) ...[
            if (i > 0) const Divider(height: AppSpace.xl),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(goal.title,
                          style: theme.textTheme.titleMedium),
                    ),
                    StatusBadge(
                      label: goal.statusEnum.label,
                      level: switch (goal.statusEnum) {
                        MainGoalStatus.active => StatusLevel.aligned,
                        MainGoalStatus.completed => StatusLevel.aligned,
                        MainGoalStatus.paused => StatusLevel.watch,
                        MainGoalStatus.archived => StatusLevel.neutral,
                      },
                    ),
                  ],
                ),
                if (goal.why.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    goal.why,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.xs),
                Text(
                  goal.completedAt != null
                      ? 'Started ${Formatters.shortDate(goal.createdAt)} · '
                          'finished ${Formatters.shortDate(goal.completedAt!)}'
                      : 'Started ${Formatters.shortDate(goal.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.textTertiary,
                  ),
                ),
              ],
            ),
          ],
      ],
    );
  }
}

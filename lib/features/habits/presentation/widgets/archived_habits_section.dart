import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../application/habits_controller.dart';
import '../../domain/habit.dart';

/// Presentation-layer view of archived habits. The main [habitsProvider]
/// filters these out; this stream keeps them one restore away.
final archivedHabitsProvider = StreamProvider<List<Habit>>(
  (ref) => ref
      .watch(habitsRepositoryProvider)
      .watchHabits(includeArchived: true)
      .map((all) => [
            for (final habit in all)
              if (habit.isArchived) habit,
          ]),
);

/// "Archived (n)" — compact rows, history intact, one tap to restore.
/// Renders nothing when no habit is archived.
class ArchivedHabitsSection extends ConsumerWidget {
  const ArchivedHabitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived =
        ref.watch(archivedHabitsProvider).valueOrNull ?? const <Habit>[];
    if (archived.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'Archived (${archived.length})'),
        for (final (index, habit) in archived.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == archived.length - 1 ? 0 : AppSpace.sm,
            ),
            child: _ArchivedRow(habit: habit),
          ),
      ],
    );
  }
}

class _ArchivedRow extends ConsumerWidget {
  const _ArchivedRow({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xs,
        AppSpace.xs,
        AppSpace.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _restore(context, ref),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(habitsControllerProvider)
          .updateHabit(habit.copyWith(isArchived: false));
    } catch (_) {
      if (context.mounted) {
        showErrorSnack(context, "That didn't save. Try again.");
      }
      return;
    }
    // The row visibly moves back to the active list — no snack needed.
    Haptics.medium();
  }
}

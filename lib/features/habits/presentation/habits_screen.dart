import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/habits_controller.dart';
import 'widgets/habit_checklist.dart';
import 'widgets/habit_editor.dart';
import 'widgets/habit_streak_card.dart';

/// Habits module: today's checklist, streaks, editor.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitsStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => HabitEditor.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Habit'),
      ),
      body: state == null
          ? const LoadingView()
          : state.habits.isEmpty
              ? EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No habits yet',
                  message:
                      'Habits support the mission. They are not the mission.',
                  actionLabel: 'Create habit',
                  onAction: () => HabitEditor.show(context),
                )
              : ContentWidth(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      HabitStreakCard(state: state),
                      const SectionHeader(title: "Today's checklist"),
                      HabitChecklist(state: state),
                      const SectionHeader(title: 'Manage'),
                      for (final view in state.habits)
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          title: Text(view.habit.name),
                          subtitle: Text(
                              '${view.streak}d streak · ${view.weeklyCount}/7 this week'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => HabitEditor.show(context,
                                    habit: view.habit),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, size: 20),
                                onPressed: () async {
                                  final confirmed = await showConfirmDialog(
                                    context,
                                    title: 'Delete habit?',
                                    message:
                                        'Deletes "${view.habit.name}" and its logs.',
                                  );
                                  if (confirmed) {
                                    await ref
                                        .read(habitsControllerProvider)
                                        .deleteHabit(view.habit.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../application/habits_controller.dart';
import 'widgets/archived_habits_section.dart';
import 'widgets/habit_checklist.dart';
import 'widgets/habit_editor.dart';
import 'widgets/habit_heatmap.dart';
import 'widgets/habit_streak_card.dart';
import '../../../ui/app_icons.dart';
import '../../../ui/tab_page_header.dart';

/// Habits — the daily support systems. One unified list: check off, see the
/// week at a glance, edit or archive from the same row.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habitsAsync = ref.watch(habitsProvider);
    final logsAsync = ref.watch(habitLogsProvider);
    final state = ref.watch(habitsStateProvider);

    // The combined state collapses stream errors to null; watch the
    // underlying streams so a broken stream shows a retry, not a spinner.
    final failed =
        state == null && (habitsAsync.hasError || logsAsync.hasError);

    return Scaffold(
      body: SafeArea(
        child: failed
            ? ErrorState(
                onRetry: () {
                  ref.invalidate(habitsProvider);
                  ref.invalidate(habitLogsProvider);
                },
              )
            : state == null
                ? const SkeletonList()
                : ContentWidth(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.screen,
                        AppSpace.lg,
                        AppSpace.screen,
                        96,
                      ),
                      children: [
                        Row(
                          children: [
                            const ScreenBackButton(),
                            Expanded(
                              child: Text('Habits',
                                  style: theme.textTheme.headlineSmall),
                            ),
                            HeaderGlyphButton(
                              icon: AppIcons.add,
                              tooltip: 'New habit',
                              onTap: () => HabitEditor.show(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          AppCopy.habitsTagline,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        if (state.habits.isEmpty)
                          EmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'Nothing to check off yet.',
                            message: 'Start with one habit you want to keep '
                                'showing up for.',
                            actionLabel: 'New habit',
                            onAction: () => HabitEditor.show(context),
                          )
                        else ...[
                          HabitStreakCard(state: state),
                          const SizedBox(height: AppSpace.cardGap),
                          HabitChecklist(state: state),
                          const SizedBox(height: AppSpace.cardGap),
                          HabitHeatmap(state: state),
                        ],
                        const ArchivedHabitsSection(),
                      ],
                    ),
                  ),
      ),
    );
  }
}

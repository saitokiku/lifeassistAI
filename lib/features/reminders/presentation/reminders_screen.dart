import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../application/reminders_controller.dart';
import 'widgets/notification_permission_card.dart';
import 'widgets/reminder_editor.dart';
import 'widgets/reminder_list.dart';

/// Reminders — the daily rhythm. Notification status up top, then the
/// day's nudges grouped by morning, afternoon, and evening.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncReminders = ref.watch(remindersProvider);
    final state = ref.watch(remindersStateProvider);

    // The empty state owns the first action; the FAB appears once a list
    // exists.
    final showFab = state != null && state.reminders.isNotEmpty;

    return Scaffold(
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => ReminderEditor.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Add reminder'),
            )
          : null,
      body: SafeArea(
        child: asyncReminders.hasError && state == null
            ? ErrorState(
                title: "Reminders didn't load.",
                onRetry: () => ref.invalidate(remindersProvider),
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
                            Text('Reminders',
                                style: theme.textTheme.headlineSmall),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          'Gentle nudges through the day.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        NotificationPermissionCard(state: state),
                        if (state.reminders.isEmpty) ...[
                          const SizedBox(height: AppSpace.sectionGap),
                          EmptyState(
                            icon: Icons.notifications_none,
                            title: 'No reminders yet',
                            message:
                                'A nudge at the right hour keeps the day on '
                                'rails. Start with a morning line and a '
                                'night review.',
                            actionLabel: 'Add reminder',
                            onAction: () => ReminderEditor.show(context),
                          ),
                        ] else
                          ReminderList(
                            reminders: state.reminders,
                            paused: state.platformSupported &&
                                !state.appNotificationsEnabled,
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

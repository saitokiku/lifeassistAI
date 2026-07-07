import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/reminders_controller.dart';
import 'widgets/notification_permission_card.dart';
import 'widgets/reminder_editor.dart';
import 'widgets/reminder_list.dart';

/// Reminders module: daily operator nudges as local notifications.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remindersStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ReminderEditor.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Reminder'),
      ),
      body: state == null
          ? const LoadingView()
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  NotificationPermissionCard(state: state),
                  const SectionHeader(title: 'Daily reminders'),
                  if (state.reminders.isEmpty)
                    EmptyState(
                      icon: Icons.notifications_none,
                      title: 'No reminders',
                      message:
                          'The scoreboard works best with a morning command and a night review.',
                      actionLabel: 'Add reminder',
                      onAction: () => ReminderEditor.show(context),
                    )
                  else
                    ReminderList(reminders: state.reminders),
                ],
              ),
            ),
    );
  }
}

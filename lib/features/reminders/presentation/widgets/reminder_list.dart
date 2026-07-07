import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../application/reminders_controller.dart';
import '../../domain/reminder.dart';
import 'reminder_editor.dart';

/// All reminders with per-reminder enable switch, edit, delete.
class ReminderList extends ConsumerWidget {
  const ReminderList({super.key, required this.reminders});

  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final reminder in reminders)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(reminder.title),
              subtitle: Text(
                '${Formatters.timeOfDay(reminder.hour, reminder.minute)} · ${reminder.typeEnum.label}\n${reminder.message}',
                maxLines: 3,
              ),
              isThreeLine: true,
              leading: Switch(
                value: reminder.enabled,
                onChanged: (v) => ref
                    .read(remindersControllerProvider)
                    .setEnabled(reminder.id, v),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    await ReminderEditor.show(context, reminder: reminder);
                  } else if (value == 'delete') {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Delete reminder?',
                      message: 'Removes "${reminder.title}".',
                    );
                    if (confirmed) {
                      await ref
                          .read(remindersControllerProvider)
                          .deleteReminder(reminder.id);
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

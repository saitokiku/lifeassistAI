import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/reminder_templates.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/reminders_controller.dart';
import '../../domain/reminder.dart';
import '../../domain/reminder_type.dart';

/// Create or edit a reminder (title, message, type, time).
class ReminderEditor extends ConsumerStatefulWidget {
  const ReminderEditor({super.key, this.reminder});

  final Reminder? reminder;

  static Future<void> show(BuildContext context, {Reminder? reminder}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ReminderEditor(reminder: reminder),
      );

  @override
  ConsumerState<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends ConsumerState<ReminderEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title =
      TextEditingController(text: widget.reminder?.title ?? '');
  late final _message =
      TextEditingController(text: widget.reminder?.message ?? '');
  late ReminderType _type = widget.reminder == null
      ? ReminderType.custom
      : ReminderType.parse(widget.reminder!.type);
  late TimeOfDay _time = widget.reminder == null
      ? const TimeOfDay(hour: 9, minute: 0)
      : TimeOfDay(hour: widget.reminder!.hour, minute: widget.reminder!.minute);

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(remindersControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final message = _message.text.trim().isEmpty
        ? ReminderTemplates.defaultMessageFor(_type.name)
        : _message.text.trim();
    try {
      if (widget.reminder == null) {
        await controller.createReminder(
          title: _title.text.trim(),
          message: message,
          type: _type.name,
          hour: _time.hour,
          minute: _time.minute,
        );
      } else {
        await controller.updateReminder(widget.reminder!.copyWith(
          title: _title.text.trim(),
          message: message,
          type: _type.name,
          hour: _time.hour,
          minute: _time.minute,
        ));
      }
      navigator.pop();
      messenger
          .showSnackBar(const SnackBar(content: Text('Reminder saved.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not save reminder.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.reminder == null ? 'New reminder' : 'Edit reminder',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Title',
              controller: _title,
              validator: (v) => Validators.required(v, label: 'Title'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Message (empty = rotating template)',
              controller: _message,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReminderType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final t in ReminderType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) =>
                  setState(() => _type = v ?? ReminderType.custom),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(_time.format(context)),
              trailing: TextButton(
                onPressed: _pickTime,
                child: const Text('Change time'),
              ),
            ),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

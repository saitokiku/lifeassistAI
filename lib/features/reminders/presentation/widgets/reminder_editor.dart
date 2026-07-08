import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/reminder_templates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/reminders_controller.dart';
import '../../domain/reminder.dart';
import '../../domain/reminder_type.dart';
import 'reminder_type_visuals.dart';

/// Create or edit a reminder.
///
/// Picking a type while creating prefills a sensible title and hour.
/// The message is either the rotating line (stored empty, previewed here)
/// or custom text — the substitution rules live in [_save].
class ReminderEditor extends ConsumerStatefulWidget {
  const ReminderEditor({super.key, this.reminder});

  final Reminder? reminder;

  static Future<void> show(BuildContext context, {Reminder? reminder}) =>
      showAppSheet<void>(
        context,
        builder: (_) => ReminderEditor(reminder: reminder),
      );

  @override
  ConsumerState<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends ConsumerState<ReminderEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.reminder?.title ?? '');
  late final _message =
      TextEditingController(text: widget.reminder?.message ?? '');
  late ReminderType _type = widget.reminder == null
      ? ReminderType.custom
      : ReminderType.parse(widget.reminder!.type);
  late TimeOfDay _time = widget.reminder == null
      ? _type.typicalTime
      : TimeOfDay(hour: widget.reminder!.hour, minute: widget.reminder!.minute);

  /// Empty stored message = rotating template. New reminders start on the
  /// rotating line so the feature is actually discoverable.
  late bool _rotating =
      widget.reminder == null || widget.reminder!.message.isEmpty;

  bool _deleting = false;

  bool get _editing => widget.reminder != null;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  void _selectType(ReminderType type) {
    if (type == _type) return;
    Haptics.select();
    setState(() {
      final previous = _type;
      _type = type;
      if (_editing) return;
      // Prefill only values the user hasn't customized yet.
      final title = _title.text.trim();
      if (title.isEmpty || title == previous.label) {
        _title.text = type == ReminderType.custom ? '' : type.label;
      }
      if (_time == previous.typicalTime) _time = type.typicalTime;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      Haptics.select();
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(remindersControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);
    // Rotating mode stores empty — that's what enables the daily template.
    // Custom mode never stores empty: an untouched field falls back to the
    // type's standard line.
    final message = _rotating
        ? ''
        : (_message.text.trim().isEmpty
            ? ReminderTemplates.defaultMessageFor(_type.name)
            : _message.text.trim());
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
      Haptics.medium();
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: AppColors.aligned),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'Saved.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textPrimaryDark),
                ),
              ),
            ],
          ),
        ));
    } catch (_) {
      if (mounted) {
        showErrorSnack(context, "That didn't save. Try again.");
      }
    }
  }

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() => _deleting = true);
    final controller = ref.read(remindersControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);
    final reminder = widget.reminder!;
    try {
      await controller.deleteReminder(reminder.id);
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        showErrorSnack(context, "That didn't delete. Try again.");
      }
      return;
    }
    Haptics.medium();
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(
          'Reminder deleted.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.textPrimaryDark),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primaryBright,
          onPressed: () {
            // Recreate from the captured row — resync handles the new id.
            controller.createReminder(
              title: reminder.title,
              message: reminder.message,
              type: reminder.type,
              hour: reminder.hour,
              minute: reminder.minute,
            );
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final todayLine =
        ReminderTemplates.rotatingMessageFor(_type.name, DateTime.now());

    return AppSheet(
      title: _editing ? 'Edit reminder' : 'New reminder',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetButton(label: 'Save', onPressed: _save),
          if (_editing) ...[
            const SizedBox(height: AppSpace.sm),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.critical),
              onPressed: _deleting ? null : _delete,
              child: const Text('Delete reminder'),
            ),
          ],
        ],
      ),
      children: [
        _Overline('TYPE'),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final type in ReminderType.values)
              _ChoiceChip(
                icon: type.glyph,
                label: type.label,
                selected: type == _type,
                onTap: () => _selectType(type),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        Form(
          key: _formKey,
          child: AppTextField(
            label: 'Title',
            controller: _title,
            validator: (v) => Validators.required(v, label: 'Title'),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Material(
          color: scheme.elevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _pickTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.lg,
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule,
                      size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      Formatters.timeOfDay(_time.hour, _time.minute),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    'Change',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.brightness == Brightness.dark
                          ? AppColors.primaryBright
                          : AppColors.primaryDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: AppSpace.xs),
          child: Text(
            'Fires daily around this time.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.textTertiary),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        _Overline('MESSAGE'),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            _ChoiceChip(
              icon: Icons.autorenew,
              label: 'Rotating line',
              selected: _rotating,
              onTap: () {
                if (_rotating) return;
                Haptics.select();
                setState(() => _rotating = true);
              },
            ),
            _ChoiceChip(
              icon: Icons.edit_outlined,
              label: 'Custom',
              selected: !_rotating,
              onTap: () {
                if (!_rotating) return;
                Haptics.select();
                setState(() => _rotating = false);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        if (_rotating)
          Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: scheme.elevated,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('“$todayLine”', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text(
                  "Today's line — a fresh one rotates in each day.",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.textTertiary),
                ),
              ],
            ),
          )
        else ...[
          AppTextField(
            label: 'Message',
            controller: _message,
            hint: 'What should the notification say?',
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: AppSpace.xs),
            child: Text(
              'Leave it empty and the standard line steps in.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.textTertiary),
            ),
          ),
        ],
      ],
    );
  }
}

class _Overline extends StatelessWidget {
  const _Overline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall
          ?.copyWith(color: theme.colorScheme.textTertiary),
    );
  }
}

/// Pill-adjacent choice chip matching the app's elevated/tinted idiom.
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.brightness == Brightness.dark
        ? AppColors.primaryBright
        : AppColors.primaryDim;

    return Material(
      color: selected
          ? Color.alphaBlend(scheme.primaryTint, scheme.elevated)
          : scheme.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        side: BorderSide(
          color: selected ? scheme.primaryTintBorder : scheme.outlineFaint,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? accent : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

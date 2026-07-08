import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/reminder_templates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../application/reminders_controller.dart';
import '../../domain/reminder.dart';
import 'reminder_editor.dart';
import 'reminder_type_visuals.dart';

/// All reminders, grouped by time of day. Row tap edits, the switch
/// toggles, a swipe deletes with undo — gestures are shortcuts, the
/// editor keeps a visible delete too.
class ReminderList extends ConsumerStatefulWidget {
  const ReminderList({
    super.key,
    required this.reminders,
    this.paused = false,
  });

  /// Stream order (hour asc, minute asc) is preserved — never re-sorted.
  final List<Reminder> reminders;

  /// True when the master toggle is off: rows dim and say so honestly.
  final bool paused;

  @override
  ConsumerState<ReminderList> createState() => _ReminderListState();
}

class _ReminderListState extends ConsumerState<ReminderList> {
  /// Rows swiped away but not yet gone from the stream — hidden so a
  /// dismissed Dismissible never lingers in the tree.
  final Set<String> _pendingDismiss = {};

  @override
  Widget build(BuildContext context) {
    // Drop stale ids once the stream catches up with a delete.
    _pendingDismiss.retainAll(widget.reminders.map((r) => r.id).toSet());

    final visible = widget.reminders
        .where((r) => !_pendingDismiss.contains(r.id))
        .toList();
    final morning = visible.where((r) => r.hour < 12).toList();
    final afternoon =
        visible.where((r) => r.hour >= 12 && r.hour < 17).toList();
    final evening = visible.where((r) => r.hour >= 17).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (morning.isNotEmpty) ...[
          const SectionHeader(title: 'Morning'),
          ..._group(morning),
        ],
        if (afternoon.isNotEmpty) ...[
          const SectionHeader(title: 'Afternoon'),
          ..._group(afternoon),
        ],
        if (evening.isNotEmpty) ...[
          const SectionHeader(title: 'Evening'),
          ..._group(evening),
        ],
      ],
    );
  }

  List<Widget> _group(List<Reminder> reminders) => [
        for (final (index, reminder) in reminders.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpace.cardGap),
          _dismissible(reminder),
        ],
      ];

  Widget _dismissible(Reminder reminder) {
    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.xl),
        decoration: BoxDecoration(
          color: AppColors.critical.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.critical),
      ),
      onDismissed: (_) => _delete(reminder),
      child: _ReminderRow(reminder: reminder, paused: widget.paused),
    );
  }

  Future<void> _delete(Reminder reminder) async {
    final controller = ref.read(remindersControllerProvider);
    setState(() => _pendingDismiss.add(reminder.id));
    Haptics.medium();
    try {
      await controller.deleteReminder(reminder.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingDismiss.remove(reminder.id));
      showErrorSnack(context, "That didn't delete. Try again.");
      return;
    }
    if (!mounted) return;
    showUndoSnack(
      context,
      'Reminder deleted.',
      onUndo: () {
        // Recreate from the captured row. A fresh notificationId is fine —
        // the controller's resync owns the OS schedule.
        controller.createReminder(
          title: reminder.title,
          message: reminder.message,
          type: reminder.type,
          hour: reminder.hour,
          minute: reminder.minute,
        );
      },
    );
  }
}

class _ReminderRow extends ConsumerWidget {
  const _ReminderRow({required this.reminder, required this.paused});

  final Reminder reminder;
  final bool paused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final type = reminder.typeEnum;
    final dimmed = paused || !reminder.enabled;

    final time = Formatters.timeOfDay(reminder.hour, reminder.minute);
    final meta = paused && reminder.enabled
        ? '$time · paused — notifications are off'
        : time;
    // Empty message means the rotating template; preview today's line so
    // the row always shows what would actually fire.
    final preview = reminder.message.isEmpty
        ? ReminderTemplates.rotatingMessageFor(reminder.type, DateTime.now())
        : reminder.message;

    return AppCard(
      onTap: () => ReminderEditor.show(context, reminder: reminder),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: dimmed ? 0.55 : 1,
            duration: AppMotion.standard,
            child: TintedIconWell(icon: type.glyph, color: type.tint),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: AnimatedOpacity(
              opacity: dimmed ? 0.55 : 1,
              duration: AppMotion.standard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Switch(
            value: reminder.enabled,
            onChanged: (value) {
              Haptics.select();
              ref
                  .read(remindersControllerProvider)
                  .setEnabled(reminder.id, value);
            },
          ),
        ],
      ),
    );
  }
}

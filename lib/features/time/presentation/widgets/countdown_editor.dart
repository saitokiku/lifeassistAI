import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/time_controller.dart';

/// Create or edit a fixed-date countdown. Dynamic countdowns (end of year,
/// age 28...) compute their own dates and only allow renaming.
class CountdownEditor extends ConsumerStatefulWidget {
  const CountdownEditor({super.key, this.countdown});

  final Countdown? countdown;

  static Future<void> show(BuildContext context, {Countdown? countdown}) =>
      showAppSheet<void>(
        context,
        builder: (_) => CountdownEditor(countdown: countdown),
      );

  @override
  ConsumerState<CountdownEditor> createState() => _CountdownEditorState();
}

class _CountdownEditorState extends ConsumerState<CountdownEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title =
      TextEditingController(text: widget.countdown?.title ?? '');
  late DateTime? _date = widget.countdown?.targetDate == null ||
          widget.countdown!.targetDate!.isEmpty
      ? null
      : AppDateUtils.parseDateKey(widget.countdown!.targetDate!);
  bool _missingDate = false;
  bool _deleting = false;

  bool get _isDynamic => widget.countdown?.dynamicKey != null;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
        _missingDate = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isDynamic && _date == null) {
      setState(() => _missingDate = true);
      return;
    }
    final controller = ref.read(timeControllerProvider);
    final navigator = Navigator.of(context);
    try {
      if (widget.countdown == null) {
        await controller.createCountdown(
            title: _title.text.trim(), targetDate: _date!);
      } else {
        await controller.updateCountdown(widget.countdown!.copyWith(
          title: _title.text.trim(),
          targetDate: _isDynamic
              ? Value(widget.countdown!.targetDate)
              : Value(AppDateUtils.dateKey(_date!)),
        ));
      }
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
      return;
    }
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Saved.');
    navigator.pop();
  }

  Future<void> _delete() async {
    if (_deleting) return;
    _deleting = true;
    try {
      final countdown = widget.countdown!;
      final controller = ref.read(timeControllerProvider);
      final navigator = Navigator.of(context);
      final raw = countdown.targetDate;
      final recreatable =
          countdown.dynamicKey == null && raw != null && raw.isNotEmpty;

      if (!recreatable) {
        // Dynamic countdowns can't be recreated from the UI — confirm first.
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete countdown?',
          message: countdown.dynamicKey != null
              ? '"${countdown.title}" computes its own date. '
                  'Once deleted it cannot be recreated.'
              : 'Removes "${countdown.title}".',
        );
        if (!confirmed || !mounted) return;
        try {
          await controller.deleteCountdown(countdown.id);
        } catch (_) {
          if (mounted) {
            showErrorSnack(context, "That didn't delete. Try again.");
          }
          return;
        }
        if (!mounted) return;
        showSuccessSnack(context, 'Deleted.');
        navigator.pop();
        return;
      }

      // Cheap to recreate: delete now, offer undo.
      final title = countdown.title;
      final target = AppDateUtils.parseDateKey(raw);
      try {
        await controller.deleteCountdown(countdown.id);
      } catch (_) {
        if (mounted) {
          showErrorSnack(context, "That didn't delete. Try again.");
        }
        return;
      }
      Haptics.medium();
      if (!mounted) return;
      showUndoSnack(
        context,
        'Countdown deleted.',
        onUndo: () =>
            controller.createCountdown(title: title, targetDate: target),
      );
      navigator.pop();
    } finally {
      _deleting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = widget.countdown == null;

    return AppSheet(
      title: isNew ? 'New countdown' : 'Edit countdown',
      subtitle: isNew ? 'A visible deadline beats a vague one.' : null,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetButton(label: 'Save', onPressed: _save),
          if (!isNew) ...[
            const SizedBox(height: AppSpace.sm),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.critical,
              ),
              onPressed: _delete,
              child: const Text('Delete countdown'),
            ),
          ],
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: AppTextField(
            label: 'Title',
            controller: _title,
            validator: (v) => Validators.required(v, label: 'Title'),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (_isDynamic)
          Row(
            children: [
              Icon(Icons.autorenew,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'This countdown computes its own date.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.input),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Target date',
                errorText: _missingDate ? 'Pick a target date.' : null,
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
              isEmpty: _date == null,
              child: _date == null
                  ? null
                  : Text(
                      Formatters.fullDate(_date!),
                      style: theme.textTheme.bodyLarge,
                    ),
            ),
          ),
      ],
    );
  }
}

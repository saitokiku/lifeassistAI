import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/focus_controller.dart';
import '../../domain/daily_action.dart';

/// Log or edit a daily action: what you did, what happened, how it went.
///
/// New entries require an honest read on the outcome — no default that
/// quietly pads the "worked" column. Saving for a day that already has an
/// entry updates that day instead of inserting a duplicate.
class ActionLogForm extends ConsumerStatefulWidget {
  const ActionLogForm({super.key, this.action, this.initialActionText});

  final DailyExperiment? action;

  /// Capture-bus prefill for the "what did you do" field (voice input).
  /// The verdict stays the user's call — voice never pads the outcome.
  final String? initialActionText;

  static Future<void> show(
    BuildContext context, {
    DailyExperiment? action,
    String? initialActionText,
  }) async {
    final message = await showAppSheet<String>(
      context,
      builder: (_) => ActionLogForm(
        action: action,
        initialActionText: initialActionText,
      ),
    );
    if (message != null && context.mounted) {
      showSuccessSnack(context, message);
    }
  }

  @override
  ConsumerState<ActionLogForm> createState() => _ActionLogFormState();
}

class _ActionLogFormState extends ConsumerState<ActionLogForm> {
  final _formKey = GlobalKey<FormState>();
  late final _action = TextEditingController(
      text: widget.action?.actionTaken ?? widget.initialActionText ?? '');
  late final _result = TextEditingController(text: widget.action?.result ?? '');
  late final _hypothesis =
      TextEditingController(text: widget.action?.hypothesis ?? '');
  late final _notes = TextEditingController(text: widget.action?.notes ?? '');

  /// Null until the user commits — new entries never default an outcome.
  late ActionVerdict? _verdict = widget.action?.verdictEnum;
  String? _verdictError;

  /// Shows the optional detail fields (idea being tested, notes). Open by
  /// default when editing an entry that already uses them.
  late bool _showDetail = (widget.action?.hypothesis.isNotEmpty ?? false) ||
      (widget.action?.notes?.isNotEmpty ?? false);

  /// Only used when logging a new entry; edits never move the date.
  DateTime _date = DateTime.now();

  /// Display order: encouraging read first.
  static const _verdictOrder = [
    ActionVerdict.worked,
    ActionVerdict.adjust,
    ActionVerdict.didntWork,
  ];

  @override
  void dispose() {
    _action.dispose();
    _result.dispose();
    _hypothesis.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  /// The action already logged for [date], if any. Guards the quick-log
  /// path against inserting a second row for the same day.
  DailyExperiment? _existingFor(DateTime date) {
    final key = AppDateUtils.dateKey(date);
    final actions = ref.read(focusStateProvider)?.actions;
    if (actions == null) return null;
    for (final a in actions) {
      if (a.date == key) return a;
    }
    return null;
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (_verdict == null) {
      setState(() => _verdictError = 'How did it go? Pick one.');
    }
    if (!valid || _verdict == null) return;

    final controller = ref.read(focusControllerProvider);
    final navigator = Navigator.of(context);
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final isNew = widget.action == null;
    final target = widget.action ?? _existingFor(_date);

    try {
      if (target == null) {
        await controller.logAction(
          date: _date,
          hypothesis: _hypothesis.text.trim(),
          actionTaken: _action.text.trim(),
          result: _result.text.trim(),
          verdict: _verdict!.storageValue,
          notes: notes,
        );
      } else {
        await controller.updateAction(target.copyWith(
          hypothesis: _hypothesis.text.trim(),
          actionTaken: _action.text.trim(),
          result: _result.text.trim(),
          verdict: _verdict!.storageValue,
          notes: Value(notes),
        ));
      }
      Haptics.medium();
      navigator.pop(isNew ? 'Logged. Small steps add up.' : 'Saved.');
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isNew = widget.action == null;

    return AppSheet(
      title: isNew ? "Log today's step" : 'Edit step',
      subtitle: 'One small action toward your goal, honestly reviewed.',
      footer: AppSheetButton(
        label: isNew ? 'Log it' : 'Save',
        onPressed: _save,
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'What did you do?',
                hint: 'The step you took, in one line.',
                controller: _action,
                autofocus: isNew,
                validator: (v) => Validators.required(v, label: 'The step'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: 'What happened?',
                hint: 'The honest outcome.',
                controller: _result,
                validator: (v) => Validators.required(v, label: 'The outcome'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                'How did it go?',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              SegmentedButton<ActionVerdict>(
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                segments: [
                  for (final v in _verdictOrder)
                    ButtonSegment(
                      value: v,
                      label: Text(v.label),
                      icon: Icon(Icons.circle, size: 8, color: v.color),
                    ),
                ],
                selected: {if (_verdict != null) _verdict!},
                onSelectionChanged: (selection) {
                  Haptics.select();
                  setState(() {
                    _verdict = selection.isEmpty ? null : selection.first;
                    _verdictError = null;
                  });
                },
              ),
              if (_verdictError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: AppSpace.xs),
                  child: Text(
                    _verdictError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.critical,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpace.sm),
              if (!_showDetail)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showDetail = true),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add detail'),
                  ),
                )
              else ...[
                const SizedBox(height: AppSpace.xs),
                AppTextField(
                  label: 'What were you testing? (optional)',
                  hint: 'If I change X, Y should move.',
                  controller: _hypothesis,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpace.md),
                AppTextField(
                  label: 'Notes (optional)',
                  controller: _notes,
                  maxLines: 2,
                ),
              ],
              if (isNew) ...[
                const SizedBox(height: AppSpace.xs),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(Formatters.fullDate(_date)),
                  trailing: Icon(
                    Icons.edit_calendar_outlined,
                    size: 18,
                    color: scheme.textTertiary,
                  ),
                  onTap: _pickDate,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

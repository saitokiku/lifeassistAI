import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/kaizen_controller.dart';
import '../../domain/daily_experiment.dart';

/// Log or edit a daily experiment: hypothesis → action → result → verdict.
///
/// New experiments require an explicit verdict — no default that quietly
/// pads the confirm column. Saving for a day that already has an experiment
/// updates that day instead of inserting a duplicate.
class ExperimentLogForm extends ConsumerStatefulWidget {
  const ExperimentLogForm({super.key, this.experiment});

  final DailyExperiment? experiment;

  static Future<void> show(
    BuildContext context, {
    DailyExperiment? experiment,
  }) async {
    final message = await showAppSheet<String>(
      context,
      builder: (_) => ExperimentLogForm(experiment: experiment),
    );
    if (message != null && context.mounted) {
      showSuccessSnack(context, message);
    }
  }

  @override
  ConsumerState<ExperimentLogForm> createState() => _ExperimentLogFormState();
}

class _ExperimentLogFormState extends ConsumerState<ExperimentLogForm> {
  final _formKey = GlobalKey<FormState>();
  late final _hypothesis =
      TextEditingController(text: widget.experiment?.hypothesis ?? '');
  late final _action =
      TextEditingController(text: widget.experiment?.actionTaken ?? '');
  late final _result =
      TextEditingController(text: widget.experiment?.result ?? '');
  late final _notes =
      TextEditingController(text: widget.experiment?.notes ?? '');

  /// Null until the user commits — new experiments never default a verdict.
  late ExperimentVerdict? _verdict = widget.experiment?.verdictEnum;
  String? _verdictError;

  /// Only used when logging a new experiment; edits never move the date.
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _hypothesis.dispose();
    _action.dispose();
    _result.dispose();
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

  /// The experiment already logged for [date], if any. Guards the quick-log
  /// path against inserting a second row for the same day.
  DailyExperiment? _existingFor(DateTime date) {
    final key = AppDateUtils.dateKey(date);
    final experiments = ref.read(kaizenStateProvider)?.experiments;
    if (experiments == null) return null;
    for (final e in experiments) {
      if (e.date == key) return e;
    }
    return null;
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (_verdict == null) {
      setState(() => _verdictError = "Pick a verdict — that's the deal.");
    }
    if (!valid || _verdict == null) return;

    final controller = ref.read(kaizenControllerProvider);
    final navigator = Navigator.of(context);
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final isNew = widget.experiment == null;
    final target = widget.experiment ?? _existingFor(_date);

    try {
      if (target == null) {
        await controller.logExperiment(
          date: _date,
          hypothesis: _hypothesis.text.trim(),
          actionTaken: _action.text.trim(),
          result: _result.text.trim(),
          verdict: _verdict!.name,
          notes: notes,
        );
      } else {
        await controller.updateExperiment(target.copyWith(
          hypothesis: _hypothesis.text.trim(),
          actionTaken: _action.text.trim(),
          result: _result.text.trim(),
          verdict: _verdict!.name,
          notes: Value(notes),
        ));
      }
      Haptics.medium();
      navigator.pop(isNew ? 'Verdict in. One test, one answer.' : 'Saved.');
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isNew = widget.experiment == null;

    return AppSheet(
      title: isNew ? 'Log experiment' : 'Edit experiment',
      subtitle: AppCopy.oneTestOneVerdict,
      footer: AppSheetButton(
        label: isNew ? 'Save verdict' : 'Update verdict',
        onPressed: _save,
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Hypothesis',
                hint: 'If I change X, Y should move.',
                controller: _hypothesis,
                validator: (v) => Validators.required(v, label: 'Hypothesis'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: 'Action taken',
                hint: 'The move you actually made.',
                controller: _action,
                validator: (v) => Validators.required(v, label: 'Action'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: 'Result',
                hint: 'What happened, plainly.',
                controller: _result,
                validator: (v) => Validators.required(v, label: 'Result'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                'Verdict',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              SegmentedButton<ExperimentVerdict>(
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                segments: [
                  for (final v in ExperimentVerdict.values)
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
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: 'Notes (optional)',
                controller: _notes,
                maxLines: 2,
              ),
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

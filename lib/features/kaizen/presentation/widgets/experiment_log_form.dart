import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/kaizen_controller.dart';
import '../../domain/daily_experiment.dart';

/// Log or edit a daily experiment: hypothesis → action → result → verdict.
class ExperimentLogForm extends ConsumerStatefulWidget {
  const ExperimentLogForm({super.key, this.experiment});

  final DailyExperiment? experiment;

  static Future<void> show(BuildContext context, {DailyExperiment? experiment}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ExperimentLogForm(experiment: experiment),
      );

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
  late ExperimentVerdict _verdict =
      widget.experiment?.verdictEnum ?? ExperimentVerdict.confirm;
  late DateTime _date = widget.experiment == null
      ? DateTime.now()
      : DateTime.parse(widget.experiment!.date);

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
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(kaizenControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    try {
      if (widget.experiment == null) {
        await controller.logExperiment(
          date: _date,
          hypothesis: _hypothesis.text.trim(),
          actionTaken: _action.text.trim(),
          result: _result.text.trim(),
          verdict: _verdict.name,
          notes: notes,
        );
      } else {
        await controller.updateExperiment(widget.experiment!.copyWith(
          hypothesis: _hypothesis.text.trim(),
          actionTaken: _action.text.trim(),
          result: _result.text.trim(),
          verdict: _verdict.name,
          notes: Value(notes),
        ));
      }
      navigator.pop();
      messenger
          .showSnackBar(const SnackBar(content: Text('Verdict logged.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not save experiment.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.experiment == null
                    ? 'Log experiment'
                    : 'Edit experiment',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(AppCopy.oneTestOneVerdict,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Hypothesis',
                controller: _hypothesis,
                validator: (v) => Validators.required(v, label: 'Hypothesis'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Action taken',
                controller: _action,
                validator: (v) => Validators.required(v, label: 'Action'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Result',
                controller: _result,
                validator: (v) => Validators.required(v, label: 'Result'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SegmentedButton<ExperimentVerdict>(
                segments: [
                  for (final v in ExperimentVerdict.values)
                    ButtonSegment(value: v, label: Text(v.label)),
                ],
                selected: {_verdict},
                onSelectionChanged: (s) => setState(() => _verdict = s.first),
              ),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Notes (optional)', controller: _notes, maxLines: 2),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(Formatters.fullDate(_date)),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Change'),
                ),
              ),
              FilledButton(onPressed: _save, child: const Text('Save verdict')),
            ],
          ),
        ),
      ),
    );
  }
}

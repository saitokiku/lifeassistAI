import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/kaizen_controller.dart';

/// Log a metric value for a date (defaults to today; replaces same-day value).
class GrowthMetricEntryForm extends ConsumerStatefulWidget {
  const GrowthMetricEntryForm({super.key, required this.metric});

  final GrowthMetric metric;

  static Future<void> show(BuildContext context, {required GrowthMetric metric}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => GrowthMetricEntryForm(metric: metric),
      );

  @override
  ConsumerState<GrowthMetricEntryForm> createState() =>
      _GrowthMetricEntryFormState();
}

class _GrowthMetricEntryFormState extends ConsumerState<GrowthMetricEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _value.dispose();
    _note.dispose();
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
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(kaizenControllerProvider).upsertEntry(
            metricId: widget.metric.id,
            date: _date,
            value: Validators.parseNumber(_value.text),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Entry saved.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save entry.')),
      );
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
            Text('Log ${widget.metric.name}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            AppNumberField(
              label: 'Value (${widget.metric.unit})',
              controller: _value,
              validator: (v) => Validators.number(v, label: 'Value'),
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Note (optional)', controller: _note),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(Formatters.fullDate(_date)),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Change'),
              ),
            ),
            FilledButton(onPressed: _save, child: const Text('Save entry')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../domain/growth_metric.dart';
import '../../domain/growth_metric_entry.dart';

/// Log a metric value for a date (defaults to today).
///
/// Upsert semantics are visible: when the selected day already has an entry,
/// the value and note prefill and the button reads "Update entry".
class GrowthMetricEntryForm extends ConsumerStatefulWidget {
  const GrowthMetricEntryForm({super.key, required this.metric, this.entry});

  final GrowthMetric metric;

  /// Optional existing entry to edit; the form opens on its date, prefilled.
  final GrowthMetricEntry? entry;

  static Future<void> show(
    BuildContext context, {
    required GrowthMetric metric,
    GrowthMetricEntry? entry,
  }) async {
    final message = await showAppSheet<String>(
      context,
      builder: (_) => GrowthMetricEntryForm(metric: metric, entry: entry),
    );
    if (message != null && context.mounted) {
      showSuccessSnack(context, message);
    }
  }

  @override
  ConsumerState<GrowthMetricEntryForm> createState() =>
      _GrowthMetricEntryFormState();
}

class _GrowthMetricEntryFormState extends ConsumerState<GrowthMetricEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date;
  GrowthMetricEntry? _existing;

  @override
  void initState() {
    super.initState();
    _date = widget.entry == null
        ? DateTime.now()
        : AppDateUtils.parseDateKey(widget.entry!.date);
    _existing = widget.entry ?? _entryFor(_date);
    final existing = _existing;
    if (existing != null) {
      _value.text = Formatters.number(existing.value);
      _note.text = existing.note ?? '';
    }
  }

  @override
  void dispose() {
    _value.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The entry already logged for [date], if any.
  GrowthMetricEntry? _entryFor(DateTime date) {
    final key = AppDateUtils.dateKey(date);
    final entries =
        ref.read(metricEntriesProvider(widget.metric.id)).valueOrNull;
    if (entries == null) return null;
    for (final e in entries) {
      if (e.date == key) return e;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;

    final found = _entryFor(picked);
    final previous = _existing;
    setState(() {
      _date = picked;
      _existing = found;
      if (found != null) {
        // Show what the save would replace.
        _value.text = Formatters.number(found.value);
        _note.text = found.note ?? '';
      } else if (previous != null) {
        // Clear stale prefills the user hasn't touched.
        if (_value.text == Formatters.number(previous.value)) _value.clear();
        if (_note.text == (previous.note ?? '')) _note.clear();
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final updating = _existing != null;
    try {
      await ref.read(focusControllerProvider).upsertEntry(
            metricId: widget.metric.id,
            date: _date,
            value: Validators.parseNumber(_value.text),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      Haptics.medium();
      navigator.pop(updating ? 'Entry updated.' : 'Logged.');
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSheet(
      title: 'Log ${widget.metric.name}',
      subtitle: 'One value per day. Logging a day again replaces it.',
      footer: AppSheetButton(
        label: _existing != null ? 'Update entry' : 'Save entry',
        onPressed: _save,
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _value,
                autofocus: true,
                validator: (v) => Validators.number(v, label: 'Value'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Value',
                  suffixText: widget.metric.unit,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(label: 'Note (optional)', controller: _note),
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
          ),
        ),
      ],
    );
  }
}

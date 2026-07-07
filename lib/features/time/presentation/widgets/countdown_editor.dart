import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/time_controller.dart';

/// Create or edit a fixed-date countdown. Dynamic countdowns (end of year,
/// age 28...) compute their own dates and only allow renaming.
class CountdownEditor extends ConsumerStatefulWidget {
  const CountdownEditor({super.key, this.countdown});

  final Countdown? countdown;

  static Future<void> show(BuildContext context, {Countdown? countdown}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
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
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isDynamic && _date == null) {
      showErrorHint();
      return;
    }
    final controller = ref.read(timeControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
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
      navigator.pop();
      messenger
          .showSnackBar(const SnackBar(content: Text('Countdown saved.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not save countdown.')));
    }
  }

  void showErrorHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pick a target date.')),
    );
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
              widget.countdown == null ? 'New countdown' : 'Edit countdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Title',
              controller: _title,
              validator: (v) => Validators.required(v, label: 'Title'),
            ),
            const SizedBox(height: 8),
            if (_isDynamic)
              Text(
                'This countdown computes its own date.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(
                    _date == null ? 'No date set' : Formatters.fullDate(_date!)),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Pick date'),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

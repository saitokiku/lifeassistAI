import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/habits_controller.dart';
import '../../application/habits_state.dart';
import '../../domain/habit.dart';

/// Value entry for numeric/duration habits. Prefills today's entry when
/// logged (edit without destroying — the note rides along), otherwise the
/// last value as a one-keystroke default.
class HabitValueSheet extends ConsumerStatefulWidget {
  const HabitValueSheet({super.key, required this.view});

  final HabitView view;

  /// Returns true when a value was logged or updated.
  static Future<bool> show(BuildContext context,
      {required HabitView view}) async {
    final logged = await showAppSheet<bool>(
      context,
      builder: (_) => HabitValueSheet(view: view),
    );
    return logged ?? false;
  }

  @override
  ConsumerState<HabitValueSheet> createState() => _HabitValueSheetState();
}

class _HabitValueSheetState extends ConsumerState<HabitValueSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _value;
  bool _saving = false;

  HabitView get _view => widget.view;

  bool get _editing => _view.todayLog != null;

  double? get _lastValue =>
      _view.logs.isNotEmpty ? _view.logs.first.value : null;

  HabitType get _type => HabitType.parse(_view.habit.type);

  String? get _unit {
    if (_type == HabitType.duration) return 'min';
    final unit = _view.habit.unit?.trim();
    return (unit == null || unit.isEmpty) ? null : unit;
  }

  @override
  void initState() {
    super.initState();
    final prefill = _view.todayLog?.value ?? _lastValue;
    final text = prefill == null ? '' : Formatters.number(prefill);
    _value = TextEditingController(text: text)
      // Typing replaces the prefill — the default is one keystroke away.
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _saving = true;
    final navigator = Navigator.of(context);
    try {
      await ref.read(habitsControllerProvider).logHabit(
            habitId: _view.habit.id,
            date: _view.today,
            value: Validators.parseNumber(_value.text),
            // Re-logging without the note would wipe it — pass it through.
            note: _view.todayLog?.note,
          );
    } catch (_) {
      _saving = false;
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
      return;
    }
    Haptics.light();
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final unit = _unit;
    final subtitle = _editing
        ? 'Logged today. Adjust if the number changed.'
        : _lastValue != null
            ? 'Last time: ${Formatters.number(_lastValue!)}'
                '${unit == null ? '' : ' $unit'}'
            : null;

    return AppSheet(
      title: _view.habit.name,
      subtitle: subtitle,
      footer: AppSheetButton(
        label: _editing ? 'Save' : 'Log it',
        onPressed: _save,
      ),
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _value,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: (v) => Validators.positiveNumber(v, label: 'Value'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onFieldSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText:
                  _type == HabitType.duration ? 'Minutes today' : 'Today',
              suffixText: unit,
            ),
          ),
        ),
      ],
    );
  }
}

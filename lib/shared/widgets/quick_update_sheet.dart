import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validation.dart';
import '../haptics.dart';
import 'app_sheet.dart';
import 'loading_view.dart';

/// One field, one save — the low-friction path for progress updates.
///
/// Opens prefilled and fully selected so typing replaces the old value.
class QuickUpdateSheet extends StatefulWidget {
  const QuickUpdateSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.label,
    required this.initialValue,
    this.suffixText,
    this.validator,
    required this.onSave,
  });

  final String title;
  final String? subtitle;
  final String label;
  final double initialValue;
  final String? suffixText;
  final String? Function(String?)? validator;
  final Future<void> Function(double value) onSave;

  /// Opens the sheet; shows a quiet "Logged." snack on success.
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String label,
    required double initialValue,
    String? suffixText,
    String? Function(String?)? validator,
    required Future<void> Function(double value) onSave,
  }) async {
    final saved = await showAppSheet<bool>(
      context,
      builder: (_) => QuickUpdateSheet(
        title: title,
        subtitle: subtitle,
        label: label,
        initialValue: initialValue,
        suffixText: suffixText,
        validator: validator,
        onSave: onSave,
      ),
    );
    if (saved == true && context.mounted) {
      showSuccessSnack(context, 'Logged.');
    }
  }

  @override
  State<QuickUpdateSheet> createState() => _QuickUpdateSheetState();
}

class _QuickUpdateSheetState extends State<QuickUpdateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _value =
      TextEditingController(text: Formatters.number(widget.initialValue));

  @override
  void initState() {
    super.initState();
    _value.selection =
        TextSelection(baseOffset: 0, extentOffset: _value.text.length);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    try {
      await widget.onSave(Validators.parseNumber(_value.text));
      Haptics.medium();
      navigator.pop(true);
    } catch (_) {
      if (mounted) {
        showErrorSnack(context, "That didn't save. Try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _value,
            autofocus: true,
            validator: widget.validator ??
                (v) => Validators.nonNegativeNumber(v, label: widget.label),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: widget.label,
              suffixText: widget.suffixText,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onFieldSubmitted: (_) => _save(),
          ),
        ),
      ],
    );
  }
}

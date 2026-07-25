import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/validation.dart';

/// Numeric input with sensible keyboard and validation.
class AppNumberField extends StatelessWidget {
  const AppNumberField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.hint,
    this.suffixText,
    this.allowNegative = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? hint;
  final String? suffixText;
  final bool allowNegative;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator ?? (v) => Validators.number(v, label: label),
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: allowNegative,
      ),
      inputFormatters: [
        // ',' is the decimal key on many keyboards; Validators
        // normalizes it, so it must survive the filter.
        FilteringTextInputFormatter.allow(
          allowNegative ? RegExp(r'[-0-9.,]') : RegExp(r'[0-9.,]'),
        ),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffixText,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}

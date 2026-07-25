import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/validation.dart';

/// Currency input: `$` prefix, decimal keyboard, digits-and-dot filter.
///
/// Local to the money feature so every sheet shares one input treatment
/// (prefix before the number, formatted prefills, optional autofocus).
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.hint,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      validator: validator ?? (v) => Validators.number(v, label: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        // The decimal key types ',' on most European/Latin American
        // keyboards; it must be kept (Validators normalizes it), not
        // silently dropped — dropping turned "4,50" into 450.
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: r'$',
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}

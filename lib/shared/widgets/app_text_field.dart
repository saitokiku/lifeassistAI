import 'package:flutter/material.dart';

/// Standard labeled text field for forms.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.hint,
    this.maxLines = 1,
    this.textInputAction,
    this.autofocus = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? hint;
  final int maxLines;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      autofocus: autofocus,
      textInputAction: textInputAction ??
          (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, hintText: hint),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}

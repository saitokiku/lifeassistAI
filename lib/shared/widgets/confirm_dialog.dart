import 'package:flutter/material.dart';

import 'app_sheet.dart';

/// Confirmation for destructive actions. Returns true when confirmed.
///
/// Kept as the app-wide entry point; renders as a bottom sheet rather than
/// a blocking dialog so confirms live where thumbs are.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) {
  return showConfirmSheet(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    destructive: destructive,
  );
}

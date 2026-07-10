import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Snack variants that take a pre-captured [ScaffoldMessengerState].
///
/// The shared showSuccessSnack/showUndoSnack helpers need a live
/// BuildContext, but ideas feedback fires after an await that disposes
/// the triggering widget: a verdict regroups (and unmounts) its card via
/// the drift stream, and the capture sheet pops before its snack shows.
/// These mirror the shared helpers' styling exactly.
void showIdeaSuccessSnack(
  ScaffoldMessengerState messenger,
  TextTheme textTheme,
  String message,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 18, color: AppColors.aligned),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textPrimaryDark),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Error feedback: human copy, never raw exceptions.
void showIdeaErrorSnack(
  ScaffoldMessengerState messenger,
  TextTheme textTheme,
  String message,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 18, color: AppColors.critical),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textPrimaryDark),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Feedback with an inline undo — verdicts are cheap to reverse, so they
/// never need a blocking confirmation.
void showIdeaUndoSnack(
  ScaffoldMessengerState messenger,
  TextTheme textTheme,
  String message, {
  required VoidCallback onUndo,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(
          message,
          style:
              textTheme.bodyMedium?.copyWith(color: AppColors.textPrimaryDark),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primaryBright,
          onPressed: onUndo,
        ),
      ),
    );
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../haptics.dart';

/// Opens a modal bottom sheet with the app's standard chrome:
/// keyboard-safe, safe-area aware, width-constrained on large screens.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: builder,
  );
}

/// Standard sheet layout: drag handle, title, optional subtitle, content,
/// footer. Content scrolls when tall; the keyboard pushes the sheet up.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Usually an [AppSheetButton]; pinned below the content.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(title, style: theme.textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpace.xl),
            ...children,
            if (footer != null) ...[
              const SizedBox(height: AppSpace.xxl),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-width primary button for sheet footers.
///
/// Owns its busy state: while the async [onPressed] runs, the button
/// disables and shows a spinner — double-submits are impossible.
class AppSheetButton extends StatefulWidget {
  const AppSheetButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final Future<void> Function()? onPressed;
  final bool destructive;

  @override
  State<AppSheetButton> createState() => _AppSheetButtonState();
}

class _AppSheetButtonState extends State<AppSheetButton> {
  bool _busy = false;

  Future<void> _handle() async {
    if (_busy || widget.onPressed == null) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      style: widget.destructive
          ? FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            )
          : null,
      onPressed:
          widget.onPressed == null || _busy ? null : () => _handle(),
      child: _busy
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: widget.destructive
                    ? scheme.onError
                    : AppColors.onPrimary,
              ),
            )
          : Text(widget.label),
    );
  }
}

/// Sheet-based confirmation for destructive actions. Returns true only on
/// explicit confirm — dismissing is a "no".
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (sheetContext) => AppSheet(
      title: title,
      children: [
        Text(message, style: Theme.of(sheetContext).textTheme.bodyMedium),
        const SizedBox(height: AppSpace.xxl),
        AppSheetButton(
          label: confirmLabel,
          destructive: destructive,
          onPressed: () async {
            Haptics.medium();
            Navigator.of(sheetContext).pop(true);
          },
        ),
        const SizedBox(height: AppSpace.sm),
        TextButton(
          onPressed: () => Navigator.of(sheetContext).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  return result ?? false;
}

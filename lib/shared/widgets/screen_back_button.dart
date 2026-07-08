import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Compact back affordance for screens reached by pushing (e.g. from the
/// You hub). Renders nothing when there's nowhere to go back to — the same
/// screen is a tab root on wide layouts.
class ScreenBackButton extends StatelessWidget {
  const ScreenBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.canPop()) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        onPressed: () => context.pop(),
        tooltip: 'Back',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import 'app_icons.dart';
import 'pressable.dart';

/// One tab destination as the console renders it.
class ConsoleDestination {
  const ConsoleDestination({
    required this.branchIndex,
    required this.label,
    required this.icon,
  });

  /// StatefulShellRoute branch this tab drives.
  final int branchIndex;
  final String label;
  final IconData icon;
}

/// The v2 bottom bar: a floating dark pill — two tabs, the raised
/// Capture button dead center, two tabs. No Material NavigationBar, no
/// indicator pill, no ripple; selection is a color shift plus a small
/// dot, presses are scale-and-dim with a selection haptic.
///
/// "You" deliberately left the bar (it lives in every screen header),
/// which is what buys the perfectly centered capture button.
class ConsoleTabBar extends StatelessWidget {
  const ConsoleTabBar({
    super.key,
    required this.currentBranch,
    required this.onSelect,
    required this.onCapture,
  });

  final int currentBranch;
  final ValueChanged<int> onSelect;
  final VoidCallback onCapture;

  static const destinations = [
    ConsoleDestination(branchIndex: 0, label: 'Today', icon: AppIcons.today),
    ConsoleDestination(branchIndex: 1, label: 'Focus', icon: AppIcons.focus),
    ConsoleDestination(branchIndex: 2, label: 'Money', icon: AppIcons.money),
    ConsoleDestination(branchIndex: 3, label: 'Time', icon: AppIcons.time),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 6, AppSpace.lg, 0),
        // A Row (not Center) so the slot's height stays the bar's 64px —
        // Center would expand to fill the bottomNavigationBar constraints
        // and squeeze the body to zero.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.elevatedDark.withValues(alpha: 0.98)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? AppColors.outlineDark
                          : AppColors.outlineLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      for (final d in destinations.sublist(0, 2))
                        Expanded(child: _tab(context, d)),
                      ConsoleCaptureButton(onPressed: onCapture),
                      for (final d in destinations.sublist(2))
                        Expanded(child: _tab(context, d)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, ConsoleDestination d) => ConsoleTabItem(
        destination: d,
        selected: d.branchIndex == currentBranch,
        onTap: () => onSelect(d.branchIndex),
      );
}

class ConsoleTabItem extends StatelessWidget {
  const ConsoleTabItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
    this.vertical = false,
  });

  final ConsoleDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryBright : AppColors.primaryDim;
    final idleColor = theme.colorScheme.onSurfaceVariant;
    final color = selected ? activeColor : idleColor;

    return Pressable(
      onTap: onTap,
      haptic: PressHaptic.select,
      semanticLabel: destination.label,
      pressedScale: 0.92,
      child: Semantics(
        selected: selected,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppMotion.tabSwitch,
              curve: AppMotion.easeOut,
              height: 3,
              width: selected ? 14 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: selected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(destination.icon, size: 21, color: color),
            const SizedBox(height: 3),
            Text(
              destination.label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                letterSpacing: 0.2,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The raised teal circle in the bar's center — the app's single
/// capture entry point (quick add today, the Capture Inbox next).
class ConsoleCaptureButton extends StatelessWidget {
  const ConsoleCaptureButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Capture',
      child: Pressable(
        onTap: onPressed,
        haptic: PressHaptic.medium,
        semanticLabel: 'Capture',
        pressedScale: 0.9,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryBright, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              AppIcons.capture,
              size: 24,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Wide-layout (Pixel Fold inner screen, iPad, desktop) counterpart:
/// the same glyph language stacked in a side column, capture on top.
class ConsoleRail extends StatelessWidget {
  const ConsoleRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.onCapture,
  });

  /// (label, icon, route-index) triples in display order.
  final List<ConsoleDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ConsoleCaptureButton(onPressed: onCapture),
              const SizedBox(height: AppSpace.xl),
              for (final (i, d) in destinations.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: SizedBox(
                    height: 58,
                    width: 76,
                    child: ConsoleTabItem(
                      destination: d,
                      selected: i == selectedIndex,
                      onTap: () => onSelect(i),
                      vertical: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

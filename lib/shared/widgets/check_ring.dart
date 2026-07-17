import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../haptics.dart';

/// One-tap circular check-in: empty ring morphs into a filled check.
///
/// The core interaction for habits and daily rituals. Fires a light haptic
/// on tap; the parent owns the actual state change.
class CheckRing extends StatelessWidget {
  const CheckRing({
    super.key,
    required this.checked,
    this.onTap,
    this.size = 28,
    this.color,
    this.semanticLabel,
  });

  final bool checked;
  final VoidCallback? onTap;
  final double size;
  final Color? color;

  /// What this ring checks off ("Stretch", "Morning pages") — read by
  /// screen readers along with the checked state. Decorative rings
  /// (inside a larger labeled tappable) leave it null and are skipped.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = color ?? AppColors.primary;

    final ring = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              Haptics.light();
              onTap!();
            },
      // Interactive rings pad out to a generous tap target; decorative rings
      // (inside a larger tappable) stay compact.
      child: Padding(
        padding: onTap == null
            ? EdgeInsets.zero
            : EdgeInsets.all((44 - size).clamp(0, 44) / 2),
        child: AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? fill : Colors.transparent,
            border: Border.all(
              color: checked ? fill : scheme.outline,
              width: 2,
            ),
          ),
          child: AnimatedScale(
            scale: checked ? 1 : 0,
            duration: AppMotion.emphasized,
            curve: AppMotion.spring,
            child: Icon(
              Icons.check_rounded,
              size: size * 0.62,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );

    if (semanticLabel == null) return ring;
    return Semantics(
      label: semanticLabel,
      checked: checked,
      button: onTap != null,
      excludeSemantics: true,
      child: ring,
    );
  }
}

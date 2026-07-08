import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// The base surface for every card in the app.
///
/// Tappable cards get a subtle press-scale plus ink; `tinted` renders the
/// brand-washed variant used for hero moments (Today's focus).
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(AppSpace.cardPadding),
    this.tinted = false,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;

  /// Brand-tinted hero variant.
  final bool tinted;

  /// Overrides the surface color (e.g. status-tinted alerts).
  final Color? color;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.brightness == Brightness.dark
        ? AppColors.cardDark
        : AppColors.cardLight;

    final color = widget.color ??
        (widget.tinted
            ? Color.alphaBlend(scheme.primaryTint, baseColor)
            : baseColor);
    final borderColor =
        widget.tinted ? scheme.primaryTintBorder : scheme.outlineFaint;

    final interactive = widget.onTap != null || widget.onLongPress != null;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onHighlightChanged: interactive
              ? (value) => setState(() => _pressed = value)
              : null,
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

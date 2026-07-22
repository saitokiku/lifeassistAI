import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../shared/haptics.dart';

/// The v2 interaction primitive: press feedback is a quick scale-and-dim,
/// never an ink ripple. Everything tappable in the new design system —
/// cards, buttons, chips, tab glyphs — builds on this one widget so the
/// whole app shares a single touch feel.
///
/// Accessibility is not optional: the widget always emits button
/// semantics (with [semanticLabel] when the child isn't self-describing)
/// and keeps a 44px minimum hit target unless [dense].
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = PressHaptic.none,
    this.pressedScale = 0.97,
    this.pressedOpacity = 0.82,
    this.semanticLabel,
    this.dense = false,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Which haptic fires on tap-down of an enabled press.
  final PressHaptic haptic;

  final double pressedScale;
  final double pressedOpacity;
  final String? semanticLabel;

  /// Skips the 44px minimum constraint (for inline text-sized taps).
  final bool dense;

  final HitTestBehavior behavior;

  bool get enabled => onTap != null || onLongPress != null;

  @override
  State<Pressable> createState() => _PressableState();
}

enum PressHaptic { none, light, select, medium }

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !widget.enabled) return;
    setState(() => _pressed = value);
  }

  void _fireHaptic() {
    switch (widget.haptic) {
      case PressHaptic.none:
        break;
      case PressHaptic.light:
        Haptics.light();
      case PressHaptic.select:
        Haptics.select();
      case PressHaptic.medium:
        Haptics.medium();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1,
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      child: AnimatedOpacity(
        opacity: _pressed ? widget.pressedOpacity : 1,
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        child: widget.child,
      ),
    );

    if (!widget.dense) {
      child = ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: child,
      );
    }

    child = GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) {
        _setPressed(true);
        _fireHaptic();
      },
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: child,
    );

    return Semantics(
      button: widget.enabled,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: child,
    );
  }
}

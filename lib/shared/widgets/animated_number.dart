import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Numeric text that rolls smoothly when its value changes.
///
/// Renders `format(value)` — pass the same formatter used elsewhere so the
/// resting state is identical to a plain Text. No animation on first build.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  final double value;
  final String Function(double value) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value, end: value),
      duration: reduceMotion ? Duration.zero : AppMotion.sweep,
      curve: AppMotion.easeOut,
      builder: (context, animated, _) => Text(format(animated), style: style),
    );
  }
}

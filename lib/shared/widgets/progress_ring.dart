import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Circular progress ring with a centered label. Custom-painted; the arc
/// sweeps smoothly when progress changes.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 96,
    this.strokeWidth = 8,
    this.center,
  });

  /// 0..1 (values above 1 render as a full ring).
  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: clamped, end: clamped),
        duration: reduceMotion ? Duration.zero : AppMotion.sweep,
        curve: AppMotion.easeOut,
        builder: (context, animated, child) => CustomPaint(
          painter: _RingPainter(
            progress: animated,
            color: color,
            trackColor: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.8),
            strokeWidth: strokeWidth,
          ),
          child: child,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    if (progress > 0) {
      final arc = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

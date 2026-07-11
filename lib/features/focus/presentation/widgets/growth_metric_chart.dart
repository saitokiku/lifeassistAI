import 'package:flutter/material.dart';

/// Lightweight custom sparkline with a soft area fill under the line.
/// Null values (no data yet) leave gaps.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, required this.color});

  final List<double?> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasData = values.any((v) => v != null);
    if (!hasData) {
      return Center(
        child: Text(
          'No entries yet',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return CustomPaint(
      size: const Size(double.infinity, 48),
      painter: _SparklinePainter(
        values: values,
        color: color,
        gridColor: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<double?> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final present = values.whereType<double>().toList();
    if (present.isEmpty) return;

    var min = present.reduce((a, b) => a < b ? a : b);
    var max = present.reduce((a, b) => a > b ? a : b);
    if (min == max) {
      min -= 1;
      max += 1;
    }
    final range = max - min;

    // Baseline grid.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, size.height - 1), Offset(size.width, size.height - 1), grid);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = color;

    final n = values.length;
    Offset pointFor(int i, double v) {
      final x = n == 1 ? size.width / 2 : i / (n - 1) * size.width;
      final y = size.height - ((v - min) / range) * (size.height - 6) - 3;
      return Offset(x, y);
    }

    // Draw each contiguous segment as a line plus a soft area fill.
    var i = 0;
    while (i < n) {
      if (values[i] == null) {
        i++;
        continue;
      }
      final start = i;
      while (i < n && values[i] != null) {
        i++;
      }
      final end = i; // exclusive

      final first = pointFor(start, values[start]!);
      if (end - start == 1) {
        canvas.drawCircle(first, 2, dot);
        continue;
      }

      final line = Path()..moveTo(first.dx, first.dy);
      for (var j = start + 1; j < end; j++) {
        final p = pointFor(j, values[j]!);
        line.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(line, stroke);

      final last = pointFor(end - 1, values[end - 1]!);
      final area = Path.from(line)
        ..lineTo(last.dx, size.height - 1)
        ..lineTo(first.dx, size.height - 1)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromLTWH(0, 0, size.width, size.height),
          ),
      );
    }

    // Emphasize the latest point.
    for (var j = n - 1; j >= 0; j--) {
      final v = values[j];
      if (v != null) {
        canvas.drawCircle(pointFor(j, v), 3.5, dot);
        break;
      }
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

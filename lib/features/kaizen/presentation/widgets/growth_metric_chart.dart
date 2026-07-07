import 'package:flutter/material.dart';

/// Lightweight custom sparkline. Null values (no data yet) leave gaps.
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
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = color;

    final n = values.length;
    Offset pointFor(int i, double v) {
      final x = n == 1 ? size.width / 2 : i / (n - 1) * size.width;
      final y = size.height - ((v - min) / range) * (size.height - 6) - 3;
      return Offset(x, y);
    }

    Path? path;
    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v == null) {
        path = null;
        continue;
      }
      final p = pointFor(i, v);
      if (path == null) {
        path = Path()..moveTo(p.dx, p.dy);
        canvas.drawCircle(p, 2, dot);
      } else {
        path.lineTo(p.dx, p.dy);
        canvas.drawPath(path, stroke);
        path = Path()..moveTo(p.dx, p.dy);
      }
    }

    // Emphasize the latest point.
    for (var i = n - 1; i >= 0; i--) {
      final v = values[i];
      if (v != null) {
        canvas.drawCircle(pointFor(i, v), 3.5, dot);
        break;
      }
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

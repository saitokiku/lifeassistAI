import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../graph/graph_model.dart';

/// The rendered link map: edges under, nodes over, labels beneath —
/// inside an [InteractiveViewer] so the vault pans and pinches like a
/// map. Tapping within a node's halo reports it.
class GraphView extends StatefulWidget {
  const GraphView({
    super.key,
    required this.graph,
    required this.positions,
    required this.canvasSize,
    this.onTapNode,
    this.focusId,
    this.fit = false,
  });

  final NoteGraph graph;
  final List<Offset> positions;

  /// The square layout space the positions were computed in.
  final double canvasSize;

  final ValueChanged<GraphNode>? onTapNode;

  /// Highlighted node (the note being viewed in the local graph).
  final String? focusId;

  /// True scales the whole graph into view (the detail mini-map);
  /// false starts centered at 1:1 and lets the user roam.
  final bool fit;

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> {
  final _transform = TransformationController();
  Size? _framedFor;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Centers (or fits) the canvas in the viewport once per viewport size.
  void _frame(Size viewport) {
    if (_framedFor == viewport) return;
    _framedFor = viewport;
    final canvas = widget.canvasSize;
    final scale = widget.fit
        ? (viewport.shortestSide / canvas).clamp(0.05, 1.0)
        : 1.0;
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - canvas * scale) / 2,
        (viewport.height - canvas * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _handleTap(TapUpDetails details) {
    final onTap = widget.onTapNode;
    if (onTap == null) return;
    final p = details.localPosition;
    GraphNode? best;
    var bestDist = 24.0; // generous halo
    for (var i = 0; i < widget.graph.nodes.length; i++) {
      final d = (widget.positions[i] - p).distance;
      if (d < bestDist) {
        bestDist = d;
        best = widget.graph.nodes[i];
      }
    }
    if (best != null) onTap(best);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      _frame(constraints.biggest);
      return InteractiveViewer(
        transformationController: _transform,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(400),
        minScale: 0.1,
        maxScale: 4,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _handleTap,
          child: CustomPaint(
            size: Size.square(widget.canvasSize),
            painter: _GraphPainter(
              graph: widget.graph,
              positions: widget.positions,
              focusId: widget.focusId,
              edgeColor: scheme.outlineVariant,
              labelColor: scheme.onSurfaceVariant,
              ghostColor: scheme.textTertiary,
              labelStyle: theme.textTheme.labelSmall,
            ),
          ),
        ),
      );
    });
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.graph,
    required this.positions,
    required this.focusId,
    required this.edgeColor,
    required this.labelColor,
    required this.ghostColor,
    required this.labelStyle,
  });

  final NoteGraph graph;
  final List<Offset> positions;
  final String? focusId;
  final Color edgeColor;
  final Color labelColor;
  final Color ghostColor;
  final TextStyle? labelStyle;

  /// Tag color buckets; untagged notes wear the brand color dimmed.
  static const _palette = [
    AppColors.primary,
    AppColors.aligned,
    AppColors.watch,
    AppColors.critical,
    AppColors.primaryBright,
    AppColors.neutral,
  ];

  static double radiusFor(GraphNode node) =>
      node.isGhost ? 5.0 : 6.0 + 1.2 * (node.degree > 8 ? 8 : node.degree);

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = edgeColor.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (final e in graph.edges) {
      canvas.drawLine(positions[e.a], positions[e.b], edgePaint);
    }

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < graph.nodes.length; i++) {
      final node = graph.nodes[i];
      final p = positions[i];
      final r = radiusFor(node);

      if (node.id == focusId) {
        canvas.drawCircle(
          p,
          r + 5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AppColors.primary.withValues(alpha: 0.5),
        );
      }

      if (node.isGhost) {
        // Hollow: a note the vault is still owed.
        canvas.drawCircle(p, r, stroke..color = ghostColor);
      } else {
        final color = node.colorBucket < 0
            ? AppColors.primary.withValues(alpha: 0.85)
            : _palette[node.colorBucket % _palette.length];
        canvas.drawCircle(p, r, fill..color = color);
      }

      // Label under the node, softly truncated.
      var label = node.title;
      if (label.length > 18) label = '${label.substring(0, 17)}…';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: (labelStyle ?? const TextStyle(fontSize: 10)).copyWith(
            color: node.isGhost ? ghostColor : labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 120);
      tp.paint(canvas, p + Offset(-tp.width / 2, r + 3));
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.graph != graph ||
      old.positions != positions ||
      old.focusId != focusId ||
      old.edgeColor != edgeColor;
}

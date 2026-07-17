/// Deterministic force-directed layout (Fruchterman–Reingold with
/// cooling). No randomness anywhere: nodes seed onto a golden-angle
/// spiral keyed by a content hash, so the same vault always settles
/// into the same shape — the map stays recognizable between visits.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'graph_model.dart';

class ForceLayout {
  ForceLayout._();

  /// Positions for every node of [graph], inside a square of [size]
  /// logical pixels with a small margin. O(n² · iterations) — fine into
  /// the high hundreds of notes; revisit off-thread beyond that.
  static List<Offset> compute(
    NoteGraph graph, {
    double size = 1200,
    int iterations = 250,
  }) {
    final n = graph.nodes.length;
    if (n == 0) return const [];
    final center = Offset(size / 2, size / 2);
    if (n == 1) return [center];

    // Seed: golden-angle spiral, ordered by node id hash so insertion
    // order doesn't reshuffle the whole map.
    const golden = 2.399963229728653; // radians
    final seedOrder = List<int>.generate(n, (i) => i)
      ..sort((a, b) =>
          stableHash(graph.nodes[a].id).compareTo(stableHash(graph.nodes[b].id)));
    final pos = List<Offset>.filled(n, Offset.zero);
    for (var rank = 0; rank < n; rank++) {
      final i = seedOrder[rank];
      final r = size * 0.4 * math.sqrt((rank + 0.5) / n);
      final theta = rank * golden;
      pos[i] = center + Offset(r * math.cos(theta), r * math.sin(theta));
    }

    final area = size * size;
    final k = math.sqrt(area / n); // ideal spring length
    final disp = List<Offset>.filled(n, Offset.zero);
    var temperature = size / 8;
    final cooling = math.pow(0.01, 1 / iterations).toDouble();

    for (var iter = 0; iter < iterations; iter++) {
      for (var i = 0; i < n; i++) {
        disp[i] = Offset.zero;
      }

      // Repulsion between every pair.
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          var delta = pos[i] - pos[j];
          var dist = delta.distance;
          if (dist < 0.01) {
            // Coincident points: separate along a deterministic axis.
            delta = Offset(((i + j) % 7 - 3) * 0.1, ((i * 31 + j) % 5 - 2) * 0.1 + 0.05);
            dist = delta.distance;
          }
          final force = (k * k) / dist;
          final push = delta / dist * force;
          disp[i] += push;
          disp[j] -= push;
        }
      }

      // Attraction along edges.
      for (final e in graph.edges) {
        var delta = pos[e.a] - pos[e.b];
        final dist = math.max(delta.distance, 0.01);
        final force = (dist * dist) / k;
        final pull = delta / dist * force;
        disp[e.a] -= pull;
        disp[e.b] += pull;
      }

      // Gentle gravity keeps disconnected islands on the map.
      for (var i = 0; i < n; i++) {
        final toCenter = center - pos[i];
        disp[i] += toCenter * 0.02;
      }

      // Move, capped by temperature; cool.
      for (var i = 0; i < n; i++) {
        final d = disp[i];
        final dist = d.distance;
        if (dist < 0.01) continue;
        final step = math.min(dist, temperature);
        var next = pos[i] + d / dist * step;
        next = Offset(
          next.dx.clamp(size * 0.04, size * 0.96),
          next.dy.clamp(size * 0.04, size * 0.96),
        );
        pos[i] = next;
      }
      temperature *= cooling;
    }

    return pos;
  }
}

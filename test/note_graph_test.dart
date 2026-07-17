import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/features/notes/graph/force_layout.dart';
import 'package:life_dashboard/features/notes/graph/graph_model.dart';

Note note(String id, String title, {bool archived = false}) => Note(
      id: id,
      zettelId: id,
      title: title,
      content: '',
      isArchived: archived,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

NoteLink link(String id, String source, String targetTitle,
        {String? targetId}) =>
    NoteLink(
      id: id,
      sourceId: source,
      targetTitle: targetTitle,
      targetId: targetId,
    );

void main() {
  group('NoteGraph.build', () {
    test('nodes, resolved edges, degree counts', () {
      final g = NoteGraph.build(
        [note('a', 'A'), note('b', 'B'), note('c', 'C')],
        [
          link('1', 'a', 'B', targetId: 'b'),
          link('2', 'a', 'C', targetId: 'c'),
        ],
        const [],
      );
      expect(g.nodes, hasLength(3));
      expect(g.edges, hasLength(2));
      final a = g.nodes.firstWhere((n) => n.id == 'a');
      expect(a.degree, 2);
      expect(g.nodes.firstWhere((n) => n.id == 'b').degree, 1);
    });

    test('ghost targets become hollow nodes, deduped by title', () {
      final g = NoteGraph.build(
        [note('a', 'A'), note('b', 'B')],
        [
          link('1', 'a', 'Someday'),
          link('2', 'b', 'someday'), // same ghost, different case
        ],
        const [],
      );
      final ghosts = g.nodes.where((n) => n.isGhost).toList();
      expect(ghosts, hasLength(1));
      expect(ghosts.single.degree, 2);
      expect(g.edges, hasLength(2));
    });

    test('duplicate pairs and self-links collapse', () {
      final g = NoteGraph.build(
        [note('a', 'A'), note('b', 'B')],
        [
          link('1', 'a', 'B', targetId: 'b'),
          link('2', 'b', 'A', targetId: 'a'), // same pair, other direction
          link('3', 'a', 'A', targetId: 'a'), // self
        ],
        const [],
      );
      expect(g.edges, hasLength(1));
    });

    test('archived notes and their links stay off the map', () {
      final g = NoteGraph.build(
        [note('a', 'A'), note('z', 'Z', archived: true)],
        [
          link('1', 'z', 'A', targetId: 'a'), // archived source
          link('2', 'a', 'Z', targetId: 'z'), // archived target: dropped
        ],
        const [],
      );
      expect(g.nodes.map((n) => n.id), ['a']);
      expect(g.edges, isEmpty);
    });

    test('first tag colors the node; buckets are content-stable', () {
      final tags = [
        NoteTag(id: 't1', noteId: 'a', tag: 'focus'),
        NoteTag(id: 't2', noteId: 'a', tag: 'later'),
      ];
      final g1 = NoteGraph.build([note('a', 'A')], const [], tags);
      final g2 = NoteGraph.build([note('a', 'A')], const [], tags);
      expect(g1.nodes.single.colorBucket, g2.nodes.single.colorBucket);
      expect(g1.nodes.single.colorBucket,
          inInclusiveRange(0, NoteGraph.colorBucketCount - 1));
      final untagged = NoteGraph.build([note('a', 'A')], const [], const []);
      expect(untagged.nodes.single.colorBucket, -1);
    });

    test('neighborhood keeps the node, its neighbors, and their edges', () {
      final g = NoteGraph.build(
        [note('a', 'A'), note('b', 'B'), note('c', 'C'), note('d', 'D')],
        [
          link('1', 'a', 'B', targetId: 'b'),
          link('2', 'b', 'C', targetId: 'c'),
          link('3', 'c', 'D', targetId: 'd'),
        ],
        const [],
      );
      final local = g.neighborhood('b');
      expect(local.nodes.map((n) => n.id).toSet(), {'a', 'b', 'c'});
      expect(local.edges, hasLength(2));
      // Edges reference the remapped node list, not the old indices.
      for (final e in local.edges) {
        expect(e.a, lessThan(local.nodes.length));
        expect(e.b, lessThan(local.nodes.length));
      }
    });
  });

  group('ForceLayout', () {
    NoteGraph ring(int n) => NoteGraph.build(
          [for (var i = 0; i < n; i++) note('n$i', 'N$i')],
          [
            for (var i = 0; i < n; i++)
              link('l$i', 'n$i', 'N${(i + 1) % n}',
                  targetId: 'n${(i + 1) % n}'),
          ],
          const [],
        );

    test('deterministic: same graph, same positions', () {
      final g = ring(12);
      final p1 = ForceLayout.compute(g);
      final p2 = ForceLayout.compute(g);
      expect(p1, p2);
    });

    test('positions are finite and inside the canvas', () {
      final g = ring(30);
      const size = 1000.0;
      final p = ForceLayout.compute(g, size: size);
      for (final o in p) {
        expect(o.dx.isFinite && o.dy.isFinite, isTrue);
        expect(o.dx, inInclusiveRange(0, size));
        expect(o.dy, inInclusiveRange(0, size));
      }
    });

    test('linked nodes sit closer than the average unlinked pair', () {
      // Two tight clusters joined by nothing: a-b-c and x-y-z.
      final g = NoteGraph.build(
        [
          note('a', 'A'), note('b', 'B'), note('c', 'C'),
          note('x', 'X'), note('y', 'Y'), note('z', 'Z'),
        ],
        [
          link('1', 'a', 'B', targetId: 'b'),
          link('2', 'b', 'C', targetId: 'c'),
          link('3', 'a', 'C', targetId: 'c'),
          link('4', 'x', 'Y', targetId: 'y'),
          link('5', 'y', 'Z', targetId: 'z'),
          link('6', 'x', 'Z', targetId: 'z'),
        ],
        const [],
      );
      final p = ForceLayout.compute(g);
      double d(String i, String j) {
        final ni = g.nodes.indexWhere((n) => n.id == i);
        final nj = g.nodes.indexWhere((n) => n.id == j);
        return (p[ni] - p[nj]).distance;
      }

      final linked = (d('a', 'b') + d('b', 'c') + d('x', 'y')) / 3;
      final unlinked = (d('a', 'x') + d('b', 'y') + d('c', 'z')) / 3;
      expect(linked, lessThan(unlinked));
    });

    test('handles empty and single-node graphs', () {
      expect(ForceLayout.compute(const NoteGraph(nodes: [], edges: [])),
          isEmpty);
      final one = NoteGraph.build([note('a', 'A')], const [], const []);
      expect(ForceLayout.compute(one), hasLength(1));
    });
  });
}

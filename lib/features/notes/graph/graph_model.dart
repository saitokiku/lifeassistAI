/// The link graph as pure data: notes (and the ghosts they cite) as
/// nodes, distinct link pairs as edges. No Flutter imports — built and
/// tested straight from drift rows.
///
/// Extensibility seam: a node is `{id, title, kind}` — nothing about it
/// is notes-specific. Journal entries, ideas, or goals can join the
/// graph later by mapping to [GraphNode]s with their own `kind` and
/// linking rows; the layout and view never ask what a node *is*.
library;

import '../../../core/storage/app_database.dart';

/// FNV-1a over code units: content-stable on every platform, unlike
/// String.hashCode — so tag colors and layout seeds never shift between
/// launches or devices.
int stableHash(String s) {
  var hash = 0x811c9dc5;
  for (final unit in s.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

class GraphNode {
  const GraphNode({
    required this.id,
    required this.title,
    required this.kind,
    required this.degree,
    required this.colorBucket,
  });

  final String id;
  final String title;

  /// 'note' or 'ghost' today; other entities are future kinds.
  final String kind;

  /// Edge count — drives node size (a hub looks like a hub).
  final int degree;

  /// Stable palette index derived from the note's first tag, or -1 for
  /// untagged/ghost nodes. The view maps buckets to actual colors.
  final int colorBucket;

  bool get isGhost => kind == 'ghost';
}

/// An undirected edge as indices into [NoteGraph.nodes].
class GraphEdge {
  const GraphEdge(this.a, this.b);

  final int a;
  final int b;
}

class NoteGraph {
  const NoteGraph({required this.nodes, required this.edges});

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  bool get isEmpty => nodes.isEmpty;

  static const int colorBucketCount = 6;

  /// Assembles the graph from raw rows. Ghost targets (links whose note
  /// doesn't exist yet) appear as their own hollow nodes — the shape of
  /// the vault includes the notes it's still owed. Self-links and
  /// duplicate pairs collapse; archived notes stay off the map.
  static NoteGraph build(
    List<Note> notes,
    List<NoteLink> links,
    List<NoteTag> tags,
  ) {
    final live = [for (final n in notes) if (!n.isArchived) n];
    final liveIds = {for (final n in live) n.id};

    // First tag per note → its color bucket.
    final firstTag = <String, String>{};
    for (final t in tags) {
      firstTag.putIfAbsent(t.noteId, () => t.tag);
    }

    // Note nodes first, then one ghost node per distinct missing title.
    final indexOf = <String, int>{};
    final protoNodes = <({String id, String title, String kind, String? tag})>[];
    for (final n in live) {
      indexOf[n.id] = protoNodes.length;
      protoNodes.add((
        id: n.id,
        title: n.title.trim().isEmpty ? 'Untitled' : n.title.trim(),
        kind: 'note',
        tag: firstTag[n.id],
      ));
    }

    String ghostId(String title) => 'ghost:${title.trim().toLowerCase()}';

    final pairs = <String>{};
    final edges = <GraphEdge>[];
    for (final link in links) {
      final source = indexOf[link.sourceId];
      if (source == null) continue; // archived or deleted source
      int? target;
      if (link.targetId != null && liveIds.contains(link.targetId)) {
        target = indexOf[link.targetId];
      } else if (link.targetId == null) {
        final gid = ghostId(link.targetTitle);
        target = indexOf[gid];
        if (target == null) {
          target = protoNodes.length;
          indexOf[gid] = target;
          protoNodes.add((
            id: gid,
            title: link.targetTitle.trim(),
            kind: 'ghost',
            tag: null,
          ));
        }
      }
      if (target == null || target == source) continue;
      final lo = source < target ? source : target;
      final hi = source < target ? target : source;
      if (pairs.add('$lo-$hi')) edges.add(GraphEdge(lo, hi));
    }

    final degrees = List<int>.filled(protoNodes.length, 0);
    for (final e in edges) {
      degrees[e.a]++;
      degrees[e.b]++;
    }

    return NoteGraph(
      nodes: [
        for (var i = 0; i < protoNodes.length; i++)
          GraphNode(
            id: protoNodes[i].id,
            title: protoNodes[i].title,
            kind: protoNodes[i].kind,
            degree: degrees[i],
            colorBucket: protoNodes[i].tag == null
                ? -1
                : stableHash(protoNodes[i].tag!) % colorBucketCount,
          ),
      ],
      edges: edges,
    );
  }

  /// The local graph: [nodeId] plus its direct neighbors and the edges
  /// among them — what the note-detail mini map shows.
  NoteGraph neighborhood(String nodeId) {
    final center = nodes.indexWhere((n) => n.id == nodeId);
    if (center < 0) return const NoteGraph(nodes: [], edges: []);

    final keep = <int>{center};
    for (final e in edges) {
      if (e.a == center) keep.add(e.b);
      if (e.b == center) keep.add(e.a);
    }
    final order = keep.toList()..sort();
    final remap = {for (var i = 0; i < order.length; i++) order[i]: i};

    return NoteGraph(
      nodes: [for (final i in order) nodes[i]],
      edges: [
        for (final e in edges)
          if (keep.contains(e.a) && keep.contains(e.b))
            GraphEdge(remap[e.a]!, remap[e.b]!),
      ],
    );
  }
}

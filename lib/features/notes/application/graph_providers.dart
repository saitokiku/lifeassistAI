import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_database.dart';
import '../graph/force_layout.dart';
import '../graph/graph_model.dart';
import 'notes_controller.dart';

final _allLinksProvider = StreamProvider<List<NoteLink>>(
  (ref) => ref.watch(notesRepositoryProvider).watchAllLinks(),
);

final _allTagRowsProvider = StreamProvider<List<NoteTag>>(
  (ref) => ref.watch(notesRepositoryProvider).watchAllTagRows(),
);

/// The whole vault as a graph, rebuilt live as notes/links/tags change.
/// Null while any source stream is still warming up.
final noteGraphProvider = Provider<NoteGraph?>((ref) {
  final notes = ref.watch(notesProvider).valueOrNull;
  final links = ref.watch(_allLinksProvider).valueOrNull;
  final tags = ref.watch(_allTagRowsProvider).valueOrNull;
  if (notes == null || links == null || tags == null) return null;
  return NoteGraph.build(notes, links, tags);
});

/// A graph plus where everything sits.
class GraphLayoutResult {
  const GraphLayoutResult(this.graph, this.positions, this.canvasSize);

  final NoteGraph graph;
  final List<Offset> positions;
  final double canvasSize;
}

/// Layout for the global graph. Deterministic, so recomputes land the
/// map in the same shape. Iterations back off as the vault grows to
/// keep the main-thread cost bounded (off-thread is the follow-up if
/// vaults reach four digits).
final graphLayoutProvider = Provider<GraphLayoutResult?>((ref) {
  final graph = ref.watch(noteGraphProvider);
  if (graph == null) return null;
  final n = graph.nodes.length;
  final iterations = n > 300 ? 60 : (n > 120 ? 120 : 250);
  const size = 1200.0;
  return GraphLayoutResult(
    graph,
    ForceLayout.compute(graph, size: size, iterations: iterations),
    size,
  );
});

/// The local mini-map around one note: its direct neighborhood, laid
/// out small. Null while loading; an empty graph means "no links yet".
final localGraphProvider =
    Provider.family<GraphLayoutResult?, String>((ref, noteId) {
  final graph = ref.watch(noteGraphProvider);
  if (graph == null) return null;
  final local = graph.neighborhood(noteId);
  const size = 480.0;
  return GraphLayoutResult(
    local,
    ForceLayout.compute(local, size: size, iterations: 150),
    size,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../data/live_vault_service.dart';
import '../data/notes_repository.dart';
import '../data/vault_service.dart';

final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => NotesRepository(ref.watch(databaseProvider)),
);

final vaultServiceProvider = Provider<VaultService>(
  (ref) => VaultService(ref.watch(databaseProvider)),
);

/// The always-on Obsidian mirror. The shell starts/stops it with the
/// app lifecycle; the Settings toggle starts/stops it by choice.
final liveVaultProvider = Provider<LiveVaultService>(
  (ref) => LiveVaultService(ref.watch(databaseProvider)),
);

/// The vault, newest-edited first. Powers the list and the You hub row.
final notesProvider = StreamProvider<List<Note>>(
  (ref) => ref.watch(notesRepositoryProvider).watchNotes(),
);

/// Resolved link count — the hub caption's honest "how connected" line.
final noteLinkCountProvider = StreamProvider<int>(
  (ref) => ref.watch(notesRepositoryProvider).watchLinkCount(),
);

/// One note, live — the detail screen re-renders on outside edits
/// (vault fold-in, another screen) without holding stale text.
///
/// autoDispose on every per-note family below: they are keyed by note
/// id, so without it each note the user opens leaves a live drift
/// subscription (and, via localGraphProvider, a cached layout) alive for
/// the whole session. unlinkedMentionsProvider is the worst of them —
/// it watches notesProvider and runs a full-table LIKE scan, so every
/// note save re-scanned the vault once per note ever visited.
final noteProvider = StreamProvider.autoDispose.family<Note?, String>(
  (ref, id) => ref.watch(notesRepositoryProvider).watchNote(id),
);

/// Who links here, with the words they used.
final backlinksProvider =
    StreamProvider.autoDispose.family<List<Backlink>, String>(
  (ref, id) => ref.watch(notesRepositoryProvider).watchBacklinks(id),
);

final noteTagsProvider =
    StreamProvider.autoDispose.family<List<NoteTag>, String>(
  (ref, id) => ref.watch(notesRepositoryProvider).watchTags(id),
);

/// Every tag row in the vault — chip rows and tag filtering.
final allTagRowsProvider = StreamProvider<List<NoteTag>>(
  (ref) => ref.watch(notesRepositoryProvider).watchAllTagRows(),
);

/// Everything including archived — the list's "show archived" mode.
final allNotesProvider = StreamProvider<List<Note>>(
  (ref) =>
      ref.watch(notesRepositoryProvider).watchNotes(includeArchived: true),
);

/// Plain-text mentions of a note's title that aren't links yet.
/// Recomputes as the vault or this note's backlinks change.
final unlinkedMentionsProvider =
    FutureProvider.autoDispose.family<List<Note>, String>((ref, id) async {
  ref.watch(notesProvider);
  ref.watch(backlinksProvider(id));
  return ref.watch(notesRepositoryProvider).unlinkedMentions(id);
});

class NotesController {
  NotesController(this._repo);

  final NotesRepository _repo;

  Future<Note> createNote({String title = '', String content = ''}) =>
      _repo.createNote(title: title, content: content);

  Future<Note> saveNote(
    Note note, {
    required String title,
    required String content,
  }) =>
      _repo.saveNote(note, title: title, content: content);

  Future<void> setArchived(String id, bool archived) =>
      _repo.setArchived(id, archived);

  Future<void> deleteNote(String id) => _repo.deleteNote(id);

  /// `[[link]]` tap: open the note bearing that title, or create it on
  /// the spot — a link to nowhere becomes a place.
  Future<Note> openOrCreateByTitle(String title) async {
    final existing = await _repo.getByTitle(title);
    if (existing != null) return existing;
    return _repo.createNote(title: title);
  }

  Future<List<String>> titleSuggestions() => _repo.allTitles();

  Future<List<String>> tagSuggestions() => _repo.allTags();
}

final notesControllerProvider = Provider<NotesController>(
  (ref) => NotesController(ref.watch(notesRepositoryProvider)),
);

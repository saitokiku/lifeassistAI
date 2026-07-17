import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/note_parsing.dart';

/// A backlink hit: the note that links here plus the raw text it used.
class Backlink {
  const Backlink({required this.source, required this.targetTitle});

  final Note source;
  final String targetTitle;
}

/// Persistence for the Zettelkasten. Notes are the source of truth;
/// NoteLinks and NoteTags are a derived index rebuilt on every save (and
/// wholesale after imports), so the graph and backlinks are always
/// consistent with the text — never hand-maintained.
class NotesRepository {
  NotesRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // ---------------------------------------------------------------- reads

  /// Newest-edited first. Archived notes stay out of the way by default.
  Stream<List<Note>> watchNotes({bool includeArchived = false}) {
    final query = _db.select(_db.notes)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    return query.watch();
  }

  Stream<Note?> watchNote(String id) =>
      (_db.select(_db.notes)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  Future<Note?> getNote(String id) =>
      (_db.select(_db.notes)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Title lookup, case-insensitive — how `[[links]]` resolve.
  Future<Note?> getByTitle(String title) async {
    final needle = title.trim().toLowerCase();
    if (needle.isEmpty) return null;
    final rows = await (_db.select(_db.notes)
          ..where((t) => t.title.lower().equals(needle))
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Notes whose text links to [noteId], with the wording they used.
  Stream<List<Backlink>> watchBacklinks(String noteId) {
    final query = _db.select(_db.noteLinks).join([
      innerJoin(_db.notes, _db.notes.id.equalsExp(_db.noteLinks.sourceId)),
    ])
      ..where(_db.noteLinks.targetId.equals(noteId))
      ..orderBy([OrderingTerm.desc(_db.notes.updatedAt)]);
    return query.watch().map((rows) => [
          for (final row in rows)
            Backlink(
              source: row.readTable(_db.notes),
              targetTitle: row.read(_db.noteLinks.targetTitle)!,
            ),
        ]);
  }

  /// Outgoing links of one note, resolved or ghost (targetId null).
  Stream<List<NoteLink>> watchOutgoingLinks(String noteId) =>
      (_db.select(_db.noteLinks)..where((t) => t.sourceId.equals(noteId)))
          .watch();

  Stream<List<NoteTag>> watchTags(String noteId) =>
      (_db.select(_db.noteTags)..where((t) => t.noteId.equals(noteId)))
          .watch();

  /// Notes whose text says this note's title without `[[linking]]` it —
  /// connections waiting to be made. Excludes itself and anyone already
  /// linking here.
  Future<List<Note>> unlinkedMentions(String noteId) async {
    final note = await getNote(noteId);
    final title = note?.title.trim() ?? '';
    if (title.isEmpty) return const [];
    final linkedSources = await (_db.selectOnly(_db.noteLinks)
          ..addColumns([_db.noteLinks.sourceId])
          ..where(_db.noteLinks.targetId.equals(noteId)))
        .get();
    final excluded = <String>{
      noteId,
      for (final row in linkedSources) row.read(_db.noteLinks.sourceId)!,
    };
    final needle =
        '%${title.replaceAll('%', '').replaceAll('_', '').toLowerCase()}%';
    return (_db.select(_db.notes)
          ..where((t) =>
              t.isArchived.equals(false) &
              t.content.lower().like(needle) &
              t.id.isNotIn(excluded.toList()))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(20))
        .get();
  }

  /// Every link row — the graph's edge list.
  Future<List<NoteLink>> allLinks() => _db.select(_db.noteLinks).get();

  /// Live edge list; the graph redraws as links are written.
  Stream<List<NoteLink>> watchAllLinks() => _db.select(_db.noteLinks).watch();

  /// Live tag rows; tag colors follow edits.
  Stream<List<NoteTag>> watchAllTagRows() => _db.select(_db.noteTags).watch();

  Stream<int> watchLinkCount() {
    final count = _db.noteLinks.id.count();
    return (_db.selectOnly(_db.noteLinks)..addColumns([count]))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  /// All live titles — the `[[` autocomplete corpus.
  Future<List<String>> allTitles() async {
    final rows = await (_db.select(_db.notes)
          ..where((t) => t.isArchived.equals(false) & t.title.equals('').not())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return [for (final n in rows) n.title];
  }

  /// Distinct tags across the vault — the `#` autocomplete corpus.
  Future<List<String>> allTags() async {
    final rows = await (_db.selectOnly(_db.noteTags, distinct: true)
          ..addColumns([_db.noteTags.tag])
          ..orderBy([OrderingTerm.asc(_db.noteTags.tag)]))
        .get();
    return [for (final row in rows) row.read(_db.noteTags.tag)!];
  }

  // --------------------------------------------------------------- writes

  /// Creates the note, indexes it, and solidifies any ghost links that
  /// were already written as `[[this title]]` before it existed.
  Future<Note> createNote({
    String title = '',
    String content = '',
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      zettelId: await _uniqueZettelId(at),
      title: title.trim(),
      content: content,
      isArchived: false,
      createdAt: at,
      updatedAt: at,
    );
    await _db.transaction(() async {
      await _db.into(_db.notes).insert(note);
      await _reindexNote(note);
      await _claimGhosts(note);
    });
    return note;
  }

  /// Saves text edits and rebuilds this note's slice of the index in the
  /// same transaction. A retitle re-resolves in both directions: links
  /// written as the new title attach here; links that meant the old
  /// title go back to ghosts (or to another note that still bears it).
  Future<Note> saveNote(
    Note note, {
    required String title,
    required String content,
    DateTime? now,
  }) async {
    final updated = note.copyWith(
      title: title.trim(),
      content: content,
      updatedAt: now ?? DateTime.now(),
    );
    await _db.transaction(() async {
      await _db.update(_db.notes).replace(updated);
      await _reindexNote(updated);
      if (note.title.trim().toLowerCase() !=
          updated.title.trim().toLowerCase()) {
        await _rehomeTitle(note.title);
        await _claimGhosts(updated);
      }
    });
    return updated;
  }

  Future<void> setArchived(String id, bool archived) =>
      (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(
          isArchived: Value(archived),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Deletes the note and its index rows; inbound links become ghosts —
  /// the text that referenced it still says what it said.
  Future<void> deleteNote(String id) => _db.transaction(() async {
        await (_db.delete(_db.noteLinks)..where((t) => t.sourceId.equals(id)))
            .go();
        await (_db.delete(_db.noteTags)..where((t) => t.noteId.equals(id)))
            .go();
        await (_db.update(_db.noteLinks)..where((t) => t.targetId.equals(id)))
            .write(const NoteLinksCompanion(targetId: Value(null)));
        await (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();
      });

  /// Rebuilds the whole derived index from note text — the recovery
  /// path after any bulk write (backup restore, vault import).
  Future<void> reindexAll() => _db.transaction(() async {
        await _db.delete(_db.noteLinks).go();
        await _db.delete(_db.noteTags).go();
        final all = await _db.select(_db.notes).get();
        final idsByTitle = {
          for (final n in all)
            if (n.title.trim().isNotEmpty) n.title.trim().toLowerCase(): n.id,
        };
        await _db.batch((batch) {
          for (final note in all) {
            final parsed = NoteParsing.parse(note.content);
            batch.insertAll(_db.noteLinks, [
              for (final target in parsed.links)
                NoteLink(
                  id: _uuid.v4(),
                  sourceId: note.id,
                  targetTitle: target,
                  targetId: idsByTitle[target.toLowerCase()],
                ),
            ]);
            batch.insertAll(_db.noteTags, [
              for (final tag in parsed.tags)
                NoteTag(id: _uuid.v4(), noteId: note.id, tag: tag),
            ]);
          }
        });
      });

  // -------------------------------------------------------------- helpers

  /// Replaces one note's link/tag rows from its current text.
  Future<void> _reindexNote(Note note) async {
    await (_db.delete(_db.noteLinks)
          ..where((t) => t.sourceId.equals(note.id)))
        .go();
    await (_db.delete(_db.noteTags)..where((t) => t.noteId.equals(note.id)))
        .go();
    final parsed = NoteParsing.parse(note.content);
    for (final target in parsed.links) {
      final resolved = await getByTitle(target);
      await _db.into(_db.noteLinks).insert(NoteLink(
            id: _uuid.v4(),
            sourceId: note.id,
            targetTitle: target,
            targetId: resolved?.id,
          ));
    }
    await _db.batch((batch) {
      batch.insertAll(_db.noteTags, [
        for (final tag in parsed.tags)
          NoteTag(id: _uuid.v4(), noteId: note.id, tag: tag),
      ]);
    });
  }

  /// Points every unresolved link written as [note]'s title at it.
  Future<void> _claimGhosts(Note note) async {
    final title = note.title.trim().toLowerCase();
    if (title.isEmpty) return;
    await (_db.update(_db.noteLinks)
          ..where((t) => t.targetId.isNull() & t.targetTitle.lower().equals(title)))
        .write(NoteLinksCompanion(targetId: Value(note.id)));
  }

  /// After a retitle: links whose text says [oldTitle] follow the words,
  /// not the row — re-point them at whichever note now holds that title,
  /// or back to ghosts if none does.
  Future<void> _rehomeTitle(String oldTitle) async {
    final title = oldTitle.trim().toLowerCase();
    if (title.isEmpty) return;
    final heir = await getByTitle(oldTitle);
    await (_db.update(_db.noteLinks)
          ..where((t) => t.targetTitle.lower().equals(title)))
        .write(NoteLinksCompanion(targetId: Value(heir?.id)));
  }

  /// Timestamp ids collide when notes are created in the same second
  /// (imports); suffix until unique so the address stays permanent.
  Future<String> _uniqueZettelId(DateTime at) async {
    final base = NoteParsing.zettelId(at);
    var candidate = base;
    var n = 1;
    while (await (_db.select(_db.notes)
              ..where((t) => t.zettelId.equals(candidate))
              ..limit(1))
            .get()
            .then((rows) => rows.isNotEmpty)) {
      candidate = '$base-${n++}';
    }
    return candidate;
  }
}

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/features/notes/data/notes_repository.dart';
import 'package:life_dashboard/features/settings/data/backup_service.dart';

void main() {
  // The backup round-trip test opens a second in-memory database on
  // purpose; silence drift's leak warning for it.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late NotesRepository repo;

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    repo = NotesRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('NotesRepository — indexing', () {
    test('saveNote indexes links and tags; resolves existing titles',
        () async {
      final target = await repo.createNote(title: 'Deep Work');
      final source = await repo.createNote(
        title: 'Morning routine',
        content: 'Read [[Deep Work]] daily. #habit #morning',
      );

      final links = await repo.allLinks();
      expect(links, hasLength(1));
      expect(links.single.sourceId, source.id);
      expect(links.single.targetTitle, 'Deep Work');
      expect(links.single.targetId, target.id);

      final tags = await repo.watchTags(source.id).first;
      expect(tags.map((t) => t.tag).toSet(), {'habit', 'morning'});
    });

    test('unresolved links are ghosts; creating the note claims them',
        () async {
      final source = await repo.createNote(
        title: 'Reading list',
        content: 'Someday: [[Atomic Habits]]',
      );

      var links = await repo.allLinks();
      expect(links.single.targetId, isNull);

      final target = await repo.createNote(title: 'Atomic Habits');
      links = await repo.allLinks();
      expect(links.single.targetId, target.id);
      expect(links.single.sourceId, source.id);
    });

    test('ghost-claim matches case-insensitively', () async {
      await repo.createNote(title: 'Notes', content: 'See [[atomic habits]]');
      final target = await repo.createNote(title: 'Atomic Habits');
      final links = await repo.allLinks();
      expect(links.single.targetId, target.id);
    });

    test('editing reindexes: removed links disappear', () async {
      final a = await repo.createNote(title: 'A');
      final b = await repo.createNote(
        title: 'B',
        content: '[[A]] matters. #keep',
      );

      await repo.saveNote(b, title: 'B', content: 'No links now.');
      expect(await repo.allLinks(), isEmpty);
      expect(await repo.watchTags(b.id).first, isEmpty);

      // The other note's rows are untouched by B's reindex.
      expect((await repo.getNote(a.id)), isNotNull);
    });

    test('rename re-homes inbound links in both directions', () async {
      final target = await repo.createNote(title: 'Old Name');
      await repo.createNote(title: 'Pointer', content: 'See [[Old Name]]');

      // Rename: the link text still says "Old Name" → back to ghost.
      await repo.saveNote(target, title: 'New Name', content: '');
      var links = await repo.allLinks();
      expect(links.single.targetId, isNull);

      // Writing to the NEW title resolves against the renamed note.
      await repo.createNote(title: 'Pointer 2', content: 'See [[New Name]]');
      links = await repo.allLinks();
      final resolved =
          links.where((l) => l.targetTitle == 'New Name').single;
      expect(resolved.targetId, target.id);
    });

    test('deleteNote drops its index rows and ghosts inbound links',
        () async {
      final target = await repo.createNote(title: 'Doomed');
      final source = await repo.createNote(
        title: 'Survivor',
        content: '[[Doomed]] #tagged',
      );

      await repo.deleteNote(target.id);
      expect(await repo.getNote(target.id), isNull);

      final links = await repo.allLinks();
      expect(links.single.sourceId, source.id);
      expect(links.single.targetId, isNull); // ghost again

      // Deleting the source removes its links + tags entirely.
      await repo.deleteNote(source.id);
      expect(await repo.allLinks(), isEmpty);
    });

    test('backlinks join returns sources newest first', () async {
      final hub = await repo.createNote(title: 'Hub');
      await repo.createNote(title: 'S1', content: '[[Hub]]');
      await repo.createNote(title: 'S2', content: 'Also [[Hub|the hub]]');

      final backs = await repo.watchBacklinks(hub.id).first;
      expect(backs, hasLength(2));
      expect(backs.map((b) => b.source.title).toSet(), {'S1', 'S2'});
      expect(backs.map((b) => b.targetTitle).toSet(), {'Hub'});
    });

    test('zettel ids are unique even in the same second', () async {
      final now = DateTime(2026, 7, 17, 12, 0, 0);
      final a = await repo.createNote(title: 'A', now: now);
      final b = await repo.createNote(title: 'B', now: now);
      final c = await repo.createNote(title: 'C', now: now);
      expect({a.zettelId, b.zettelId, c.zettelId}, hasLength(3));
      expect(a.zettelId, '20260717120000');
    });

    test('reindexAll rebuilds the whole index from text', () async {
      final a = await repo.createNote(title: 'A', content: '[[B]] #x');
      final b = await repo.createNote(title: 'B', content: '[[A]]');

      // Sabotage the derived tables, then rebuild.
      await db.delete(db.noteLinks).go();
      await db.delete(db.noteTags).go();
      expect(await repo.allLinks(), isEmpty);

      await repo.reindexAll();
      final links = await repo.allLinks();
      expect(links, hasLength(2));
      expect(
        links.firstWhere((l) => l.sourceId == a.id).targetId,
        b.id,
      );
      expect(
        links.firstWhere((l) => l.sourceId == b.id).targetId,
        a.id,
      );
      final tags = await repo.watchTags(a.id).first;
      expect(tags.single.tag, 'x');
    });
  });

  group('NotesRepository — unlinked mentions', () {
    test('plain-text mentions surface; linkers and self are excluded',
        () async {
      final target = await repo.createNote(title: 'Deep Work');
      // Mentions by name, no link → shows up.
      final mentioner = await repo.createNote(
        title: 'Reading log',
        content: 'Finished deep work yesterday.',
      );
      // Already links → excluded.
      await repo.createNote(title: 'Linker', content: 'See [[Deep Work]]');
      // Self-mention → excluded.
      await repo.saveNote(
        target,
        title: 'Deep Work',
        content: 'Deep Work is the title of this very note.',
      );

      final unlinked = await repo.unlinkedMentions(target.id);
      expect(unlinked.map((n) => n.id), [mentioner.id]);

      // Untitled notes can't be mentioned.
      final untitled = await repo.createNote(content: 'body');
      expect(await repo.unlinkedMentions(untitled.id), isEmpty);
    });
  });

  group('NotesRepository — corpora', () {
    test('allTitles skips archived and untitled; allTags is distinct',
        () async {
      await repo.createNote(title: 'Kept', content: '#one #two');
      await repo.createNote(title: '', content: '#one');
      final archived = await repo.createNote(title: 'Hidden');
      await repo.setArchived(archived.id, true);

      expect(await repo.allTitles(), ['Kept']);
      expect(await repo.allTags(), ['one', 'two']);
    });
  });

  group('Backup round-trip', () {
    test('notes export/import; link index rebuilt on restore', () async {
      await repo.createNote(title: 'Alpha', content: 'Links [[Beta]] #core');
      await repo.createNote(title: 'Beta', content: 'Back to [[Alpha]]');

      final service = BackupService(db);
      final json = await service.exportJson();
      expect(json, contains('"notes"'));

      // Restore into a fresh database.
      final db2 = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
      addTearDown(db2.close);
      final result = await BackupService(db2).importJson(json);
      expect(result.isSuccess, isTrue);

      final repo2 = NotesRepository(db2);
      final notes = await repo2.watchNotes().first;
      expect(notes.map((n) => n.title).toSet(), {'Alpha', 'Beta'});

      // Derived index was rebuilt, not imported.
      final links = await repo2.allLinks();
      expect(links, hasLength(2));
      expect(links.every((l) => l.targetId != null), isTrue);
      final alpha = notes.firstWhere((n) => n.title == 'Alpha');
      expect(
        (await repo2.watchTags(alpha.id).first).single.tag,
        'core',
      );
    });
  });
}

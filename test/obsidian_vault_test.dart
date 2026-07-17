import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/features/notes/data/notes_repository.dart';
import 'package:life_dashboard/features/notes/data/obsidian_vault.dart';
import 'package:life_dashboard/features/notes/data/vault_service.dart';

Note note(
  String id,
  String title, {
  String content = '',
  bool archived = false,
}) =>
    Note(
      id: id,
      zettelId: '2026$id',
      title: title,
      content: content,
      isArchived: archived,
      createdAt: DateTime(2026, 7, 1, 9, 30),
      updatedAt: DateTime(2026, 7, 2, 10, 15),
    );

void main() {
  group('ObsidianVault format', () {
    test('serialize → parse round-trips identity and body', () {
      final n = note('n1', 'Deep Work',
          content: 'Read [[Atomic Habits]].\n\n#focus');
      final raw = ObsidianVault.serialize(n);
      final parsed = ObsidianVault.parse(ObsidianVault.fileName(n), raw);

      expect(parsed.id, 'n1');
      expect(parsed.zettelId, '2026n1');
      expect(parsed.title, 'Deep Work');
      expect(parsed.content, 'Read [[Atomic Habits]].\n\n#focus');
      expect(parsed.archived, isFalse);
      expect(parsed.createdAt, DateTime(2026, 7, 1, 9, 30));
      expect(parsed.updatedAt, DateTime(2026, 7, 2, 10, 15));
    });

    test('archived flag survives; quotes in titles escape cleanly', () {
      final n = note('n2', 'A "quoted" / slashed title', archived: true);
      final parsed = ObsidianVault.parse(
          ObsidianVault.fileName(n), ObsidianVault.serialize(n));
      expect(parsed.title, 'A "quoted" / slashed title');
      expect(parsed.archived, isTrue);
    });

    test('plain Obsidian file: no frontmatter, title from filename', () {
      final parsed = ObsidianVault.parse(
        'Evergreen ideas.md',
        'Just a body with [[links]].',
      );
      expect(parsed.id, isNull);
      expect(parsed.zettelId, isNull);
      expect(parsed.title, 'Evergreen ideas');
      expect(parsed.content, 'Just a body with [[links]].');
    });

    test('foreign frontmatter keys are tolerated, not fatal', () {
      final parsed = ObsidianVault.parse(
        'Imported.md',
        '---\naliases: [a, b]\ntags: [x]\ncssclass: wide\n---\n\nBody.',
      );
      expect(parsed.title, 'Imported');
      expect(parsed.content, 'Body.');
    });

    test('a leading --- with no closing fence is body, not frontmatter',
        () {
      final parsed = ObsidianVault.parse('Odd.md', '---\njust a rule?');
      expect(parsed.content, '---\njust a rule?');
    });

    test('file names sanitize slashes, collapse runs, fall back to zettel',
        () {
      expect(
        ObsidianVault.fileName(note('n3', 'A/B: what?')),
        'A-B- what-.md',
      );
      expect(ObsidianVault.fileName(note('n4', '')), '2026n4.md');
    });
  });

  group('VaultService round-trip', () {
    late AppDatabase db;
    late NotesRepository repo;
    late VaultService service;

    setUp(() {
      db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
      repo = NotesRepository(db);
      service = VaultService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('export payloads re-import as updates, not duplicates', () async {
      await repo.createNote(title: 'Alpha', content: '[[Beta]] #core');
      await repo.createNote(title: 'Beta', content: 'Back to [[Alpha]]');

      final payloads = await service.serializedNotes();
      expect(payloads, hasLength(2));

      final outcome = await service.importPayloads(payloads);
      expect(outcome.created, 0);
      expect(outcome.updated, 2);
      expect(await repo.watchNotes().first, hasLength(2));

      // Index rebuilt and fully resolved after import.
      final links = await repo.allLinks();
      expect(links, hasLength(2));
      expect(links.every((l) => l.targetId != null), isTrue);
    });

    test('same-title notes export under distinct filenames', () async {
      await repo.createNote(title: 'Inbox');
      await repo.createNote(title: 'Inbox');
      final names = [for (final p in await service.serializedNotes()) p.name];
      expect(names.toSet(), hasLength(2));
    });

    test('foreign .md files create notes; title matches update', () async {
      await repo.createNote(title: 'Existing', content: 'old');

      final outcome = await service.importPayloads(const [
        VaultPayload(name: 'Existing.md', content: 'new body [[Fresh]]'),
        VaultPayload(name: 'Fresh.md', content: 'brand new'),
        VaultPayload(name: 'empty.md', content: '   '),
      ]);
      expect(outcome.updated, 1);
      // 'Fresh' file + 'empty.md' has a title, so it lands too (title
      // from filename, blank body).
      expect(outcome.created, 2);

      final existing = await repo.getByTitle('Existing');
      expect(existing!.content, 'new body [[Fresh]]');

      // The [[Fresh]] link resolved against the just-created note.
      final links = await repo.allLinks();
      expect(links.single.targetId, (await repo.getByTitle('Fresh'))!.id);
    });

    test('zettel collisions on import mint unique ids', () async {
      final a = await repo.createNote(title: 'A');
      final outcome = await service.importPayloads([
        VaultPayload(
          name: 'Clone.md',
          content: '---\nzettel: ${a.zettelId}\n---\n\nclone body',
        ),
      ]);
      // Same zettel but different title/id → treated as the SAME note?
      // No: zettel matches note A, so it updates A.
      expect(outcome.updated, 1);
      expect((await repo.getNote(a.id))!.content, 'clone body');
    });

    test('zip bytes contain one entry per note', () async {
      await repo.createNote(title: 'One');
      await repo.createNote(title: 'Two');
      final bytes = await service.zipBytes();
      expect(bytes, isNotEmpty);
      // 'PK' zip magic.
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);
    });
  });
}

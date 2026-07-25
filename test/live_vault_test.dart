import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/features/notes/data/live_vault_service.dart';
import 'package:life_dashboard/features/notes/data/notes_repository.dart';
import 'package:life_dashboard/features/notes/data/vault_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Points path_provider at a throwaway directory so the mirror writes
/// somewhere observable.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late AppDatabase db;
  late NotesRepository repo;
  late LiveVaultService vault;

  Directory vaultDir() =>
      Directory('${temp.path}/${VaultService.folderName}');

  File vaultFile(String name) => File('${vaultDir().path}/$name');

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('live_vault_test');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    repo = NotesRepository(db);
    vault = LiveVaultService(db);
  });

  tearDown(() async {
    await vault.stop();
    await db.close();
    await temp.delete(recursive: true);
  });

  test('start mirrors existing notes as Obsidian .md files', () async {
    await repo.createNote(title: 'Deep Work', content: 'Focus. #craft');
    await vault.start();

    final file = vaultFile('Deep Work.md');
    expect(await file.exists(), isTrue);
    final raw = await file.readAsString();
    expect(raw, contains('title: "Deep Work"'));
    expect(raw, contains('tags: [craft]'));
    expect(raw, contains('Focus. #craft'));
    expect(raw, isNot(contains('zettel:')));
  });

  test('save and delete write through; retitle moves the file', () async {
    await vault.start();
    final note = await repo.createNote(title: 'Alpha', content: 'one');
    await vault.mirrorNow();
    expect(await vaultFile('Alpha.md').exists(), isTrue);

    final renamed =
        await repo.saveNote(note, title: 'Beta', content: 'two');
    await vault.mirrorNow();
    expect(await vaultFile('Alpha.md').exists(), isFalse);
    expect(await vaultFile('Beta.md').exists(), isTrue);
    expect(await vaultFile('Beta.md').readAsString(), contains('two'));

    await repo.deleteNote(renamed.id);
    await vault.mirrorNow();
    expect(await vaultFile('Beta.md').exists(), isFalse);
  });

  test('outside edits fold in; mirror-written files do not echo',
      () async {
    final note = await repo.createNote(title: 'Alpha', content: 'original');
    await vault.start();

    // Untouched folder → nothing to import.
    var result = await vault.syncFromFolder();
    expect(result.total, 0);

    // An outside edit to the body lands on the note.
    final file = vaultFile('Alpha.md');
    final edited = (await file.readAsString())
        .replaceFirst('original', 'edited outside');
    await file.writeAsString(edited);
    result = await vault.syncFromFolder();
    expect(result.updated, 1);
    final row = await repo.getNote(note.id);
    expect(row!.content, 'edited outside');
  });

  test('a brand-new outside file becomes a note', () async {
    await vault.start();
    await vaultDir().create(recursive: true);
    await vaultFile('Fresh thought.md')
        .writeAsString('From Obsidian, with [[Links]].');

    final result = await vault.syncFromFolder();
    expect(result.created, 1);
    final titles = await repo.allTitles();
    expect(titles, contains('Fresh thought'));
  });

  test('stale files with our id move to trash; foreign files survive',
      () async {
    // A file claiming an id that has no note = deleted note leftover.
    await vaultDir().create(recursive: true);
    await vaultFile('Ghost.md').writeAsString(
        '---\nid: no-such-note\ntitle: "Ghost"\n---\n\nbody');
    await vaultFile('Handwritten.md').writeAsString('Just some text.');

    await vault.start();
    expect(await vaultFile('Ghost.md').exists(), isFalse);
    // Moved, not destroyed: after "Reset all data" this sweep sees an
    // empty notes table and every mirrored file as stale — deletion
    // here would erase the user's whole vault on the next launch.
    final trashed = File(
        '${vaultDir().path}/${LiveVaultService.trashFolderName}/Ghost.md');
    expect(await trashed.exists(), isTrue);
    expect(await trashed.readAsString(), contains('body'));
    // The handwritten file has no id — imported, never touched.
    expect(await vaultFile('Handwritten.md').exists(), isTrue);
    final titles = await repo.allTitles();
    expect(titles, contains('Handwritten'));
  });

  test('a stale file never overwrites a newer note; its text is parked',
      () async {
    await vault.start();
    final note =
        await repo.createNote(title: 'Alpha', content: 'newer app text');
    await vault.mirrorNow();

    // Simulate an un-synced/stale copy landing in the folder: right id,
    // old content, old mtime (an iCloud placeholder, a missed mirror).
    final file = vaultFile('Alpha.md');
    await file.writeAsString(
        '---\nid: ${note.id}\ntitle: "Alpha"\n---\n\nold stale text\n');
    file.setLastModifiedSync(
        DateTime.now().subtract(const Duration(hours: 1)));

    final result = await vault.syncFromFolder();
    expect(result.total, 0, reason: 'the stale file must not import');
    final row = await repo.getNote(note.id);
    expect(row!.content, 'newer app text',
        reason: 'the newer in-app text survives');

    // The divergent file text is preserved, not discarded.
    final conflicts = Directory(
        '${vaultDir().path}/${LiveVaultService.conflictFolderName}');
    final parked = conflicts.listSync().whereType<File>().toList();
    expect(parked, hasLength(1));
    expect(await parked.single.readAsString(), contains('old stale text'));
  });

  test('a genuinely newer outside edit still imports', () async {
    await vault.start();
    final note = await repo.createNote(title: 'Alpha', content: 'original');
    await vault.mirrorNow();

    // Fresh mtime (now) — the normal Obsidian-edit case.
    final file = vaultFile('Alpha.md');
    final edited = (await file.readAsString())
        .replaceFirst('original', 'edited outside');
    await file.writeAsString(edited);

    final result = await vault.syncFromFolder();
    expect(result.updated, 1);
    expect((await repo.getNote(note.id))!.content, 'edited outside');
  });
}

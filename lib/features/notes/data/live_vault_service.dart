import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/app_database.dart';
import 'obsidian_vault.dart';
import 'vault_service.dart';

/// The live Obsidian bridge: Documents/LifeAssistVault stops being an
/// export you remember to refresh and becomes the vault itself.
///
/// Direction 1 — write-through: every note change (save, delete,
/// archive, import, restore) mirrors to its `.md` within a second,
/// atomically (tmp + rename), with retitles moving the file. One drift
/// table watcher covers every write path in the app.
///
/// Direction 2 — fold-in on arrival: [syncFromFolder] runs at start and
/// on every app resume, importing only files that actually differ from
/// their note (or are new). Files the mirror itself wrote parse back
/// byte-identical and are skipped, so the loop terminates immediately.
///
/// Deletions are asymmetric by design: deleting a note removes its file,
/// but a file missing from the folder never deletes a note — a sync
/// hiccup in the Files app must not be able to destroy thoughts. The
/// note simply rematerializes on the next full mirror pass.
class LiveVaultService {
  LiveVaultService(this._db);

  final AppDatabase _db;

  StreamSubscription<void>? _sub;
  Timer? _debounce;
  Directory? _dir;
  Future<void> _work = Future.value();

  /// Last-written file name per note id — how retitles and deletes find
  /// the old file.
  final _fileById = <String, String>{};

  /// Last-written serialized text per note id — skips untouched notes.
  final _contentById = <String, String>{};

  bool get running => _sub != null;

  /// Sweeps stale files, folds in outside edits, mirrors everything,
  /// then stays subscribed. Safe to call twice; silently a no-op where
  /// no documents directory exists (web, tests).
  Future<void> start() async {
    if (_sub != null) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      _dir = Directory('${docs.path}/${VaultService.folderName}');
      await _dir!.create(recursive: true);
    } catch (_) {
      _dir = null;
      return;
    }
    try {
      await _sweepStale();
      await syncFromFolder();
    } catch (_) {
      // A broken file must not stop the mirror from starting.
    }
    await mirrorNow();
    _sub =
        _db.tableUpdates(TableUpdateQuery.onTable(_db.notes)).listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), mirrorNow);
    });
  }

  Future<void> stop() async {
    _debounce?.cancel();
    _debounce = null;
    await _sub?.cancel();
    _sub = null;
  }

  /// One full mirror pass, serialized so passes never interleave;
  /// failures never escape — a full disk degrades to a stale mirror,
  /// not a crash. The table watcher debounces into this.
  Future<void> mirrorNow() {
    return _work = _work.then((_) => _mirror()).catchError((_) {});
  }

  Future<void> _mirror() async {
    final dir = _dir;
    if (dir == null) return;
    final notes = await _db.select(_db.notes).get();

    // Same duplicate-title disambiguation as the exporter.
    final used = <String>{};
    final current = <String, ({String name, String content})>{};
    for (final n in notes) {
      var name = ObsidianVault.fileName(n);
      if (!used.add(name.toLowerCase())) {
        name = name.replaceFirst(RegExp(r'\.md$'), ' (${n.zettelId}).md');
        used.add(name.toLowerCase());
      }
      current[n.id] = (name: name, content: ObsidianVault.serialize(n));
    }

    // Removals and renames first so a retitle never collides with the
    // file it is replacing.
    for (final id in _fileById.keys.toList()) {
      final oldName = _fileById[id]!;
      final now = current[id];
      if (now == null || now.name != oldName) {
        try {
          await File('${dir.path}/$oldName').delete();
        } catch (_) {}
        if (now == null) {
          _fileById.remove(id);
          _contentById.remove(id);
        }
      }
    }

    for (final entry in current.entries) {
      final f = entry.value;
      if (_fileById[entry.key] == f.name &&
          _contentById[entry.key] == f.content) {
        continue;
      }
      try {
        final tmp = File('${dir.path}/.${f.name}.tmp');
        await tmp.writeAsString(f.content, flush: true);
        await tmp.rename('${dir.path}/${f.name}');
        _fileById[entry.key] = f.name;
        _contentById[entry.key] = f.content;
      } catch (_) {
        // Skip this file; the next pass retries.
      }
    }
  }

  /// Files that carry OUR frontmatter id but whose note no longer
  /// exists are leftovers of an in-app delete (from before live mode,
  /// or from another install of this database). Without this sweep the
  /// next fold-in would resurrect the deleted note. Files without our
  /// id — hand-written, Obsidian-created — are never touched.
  Future<void> _sweepStale() async {
    final dir = _dir;
    if (dir == null) return;
    final rows = await _db.select(_db.notes).get();
    final liveIds = {for (final n in rows) n.id};
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      final name = entity.uri.pathSegments.last;
      try {
        final parsed = ObsidianVault.parse(name, await entity.readAsString());
        if (parsed.id != null && !liveIds.contains(parsed.id)) {
          await entity.delete();
        }
      } catch (_) {}
    }
  }

  /// Imports every folder file that is new or differs from its matched
  /// note (same id → zettel → title chain as the importer). Runs at
  /// start and on app resume; the diff check makes it cheap and keeps
  /// mirror-written files from echoing back as imports.
  Future<VaultImportResult> syncFromFolder() async {
    final dir = _dir;
    if (dir == null) return const VaultImportResult(created: 0, updated: 0);

    final rows = await _db.select(_db.notes).get();
    final byId = {for (final n in rows) n.id: n};
    final byZettel = {for (final n in rows) n.zettelId: n};
    final byTitle = {
      for (final n in rows)
        if (n.title.trim().isNotEmpty) n.title.trim().toLowerCase(): n,
    };

    final changed = <VaultPayload>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.md') && !name.endsWith('.markdown')) continue;
      String raw;
      try {
        raw = await entity.readAsString();
      } catch (_) {
        continue;
      }
      final v = ObsidianVault.parse(name, raw);
      if (v.title.trim().isEmpty && v.content.trim().isEmpty) continue;
      final match = (v.id != null ? byId[v.id] : null) ??
          (v.zettelId != null ? byZettel[v.zettelId] : null) ??
          byTitle[v.title.trim().toLowerCase()];
      final same = match != null &&
          match.title.trim() == v.title.trim() &&
          match.content.trimRight() == v.content &&
          match.isArchived == v.archived;
      if (!same) changed.add(VaultPayload(name: name, content: raw));
    }

    if (changed.isEmpty) {
      return const VaultImportResult(created: 0, updated: 0);
    }
    return VaultService(_db).importPayloads(changed);
  }
}

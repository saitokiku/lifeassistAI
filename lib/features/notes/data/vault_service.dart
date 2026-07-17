import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/note_parsing.dart';
import 'notes_repository.dart';
import 'obsidian_vault.dart';

/// A file offered for import, wherever it came from (file picker bytes,
/// vault folder read).
class VaultPayload {
  const VaultPayload({required this.name, required this.content});

  final String name;
  final String content;
}

class VaultExportResult {
  const VaultExportResult({required this.count, required this.path});

  final int count;
  final String path;
}

class VaultImportResult {
  const VaultImportResult({required this.created, required this.updated});

  final int created;
  final int updated;

  int get total => created + updated;
}

/// Moves whole vaults across the app boundary: every note as an
/// Obsidian-compatible `.md` with frontmatter, into (and out of) a
/// Files-app-visible folder or a shareable zip. Import dedupes by
/// frontmatter id → zettel id → title, so re-importing your own export
/// updates in place instead of doubling the vault.
class VaultService {
  VaultService(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Documents/LifeAssistVault — visible in the Files app because the
  /// app declares UIFileSharingEnabled + LSSupportsOpeningDocumentsInPlace.
  static const folderName = 'LifeAssistVault';

  NotesRepository get _repo => NotesRepository(_db);

  // -------------------------------------------------------------- export

  /// Every note serialized, with duplicate-title filenames made unique
  /// by their zettel id.
  Future<List<VaultPayload>> serializedNotes() async {
    final notes = await _db.select(_db.notes).get();
    final used = <String>{};
    final payloads = <VaultPayload>[];
    for (final note in notes) {
      var name = ObsidianVault.fileName(note);
      if (!used.add(name.toLowerCase())) {
        name = name.replaceFirst(
            RegExp(r'\.md$'), ' (${note.zettelId}).md');
        used.add(name.toLowerCase());
      }
      payloads.add(
        VaultPayload(name: name, content: ObsidianVault.serialize(note)),
      );
    }
    return payloads;
  }

  /// Writes the vault into Documents/LifeAssistVault. Files this app
  /// wrote earlier whose note has since been deleted are cleaned up
  /// (recognized by their frontmatter id); anything else in the folder
  /// is left untouched. Not available on web.
  Future<VaultExportResult> exportToFolder() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$folderName');
    await dir.create(recursive: true);

    final payloads = await serializedNotes();
    final notes = await _db.select(_db.notes).get();
    final liveIds = {for (final n in notes) n.id};
    final written = <String>{};
    for (final p in payloads) {
      await File('${dir.path}/${p.name}').writeAsString(p.content);
      written.add(p.name.toLowerCase());
    }

    // Stale sweep: only files that carry OUR id frontmatter and whose
    // note no longer exists. A hand-written file is never touched.
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      final name = entity.uri.pathSegments.last;
      if (written.contains(name.toLowerCase())) continue;
      try {
        final parsed = ObsidianVault.parse(name, await entity.readAsString());
        if (parsed.id != null && !liveIds.contains(parsed.id)) {
          await entity.delete();
        }
      } catch (_) {
        // Unreadable file: leave it be.
      }
    }

    return VaultExportResult(count: payloads.length, path: dir.path);
  }

  /// The whole vault as zip bytes (works on every platform; the caller
  /// shares or saves them).
  Future<Uint8List> zipBytes() async {
    final payloads = await serializedNotes();
    final archive = Archive();
    for (final p in payloads) {
      final bytes = utf8.encode(p.content);
      archive.addFile(ArchiveFile('$folderName/${p.name}', bytes.length, bytes));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  // -------------------------------------------------------------- import

  /// Imports parsed `.md` payloads: frontmatter id, then zettel id,
  /// then case-insensitive title decide whether a file updates an
  /// existing note or creates one. Ends with a full link/tag reindex.
  Future<VaultImportResult> importPayloads(List<VaultPayload> payloads) async {
    var created = 0;
    var updated = 0;
    final now = DateTime.now();

    await _db.transaction(() async {
      final existing = await _db.select(_db.notes).get();
      final byId = {for (final n in existing) n.id: n};
      final byZettel = {for (final n in existing) n.zettelId: n};
      final byTitle = {
        for (final n in existing)
          if (n.title.trim().isNotEmpty) n.title.trim().toLowerCase(): n,
      };

      for (final payload in payloads) {
        final v = ObsidianVault.parse(payload.name, payload.content);
        if (v.title.trim().isEmpty && v.content.trim().isEmpty) continue;

        final match = (v.id != null ? byId[v.id] : null) ??
            (v.zettelId != null ? byZettel[v.zettelId] : null) ??
            byTitle[v.title.trim().toLowerCase()];

        if (match != null) {
          final row = match.copyWith(
            title: v.title.trim(),
            content: v.content,
            isArchived: v.archived,
            updatedAt: v.updatedAt ?? now,
          );
          await _db.update(_db.notes).replace(row);
          byId[row.id] = row;
          byZettel[row.zettelId] = row;
          if (row.title.trim().isNotEmpty) {
            byTitle[row.title.trim().toLowerCase()] = row;
          }
          updated++;
        } else {
          final id = (v.id != null && !byId.containsKey(v.id))
              ? v.id!
              : _uuid.v4();
          String zettel;
          final offered = v.zettelId;
          if (offered != null && !byZettel.containsKey(offered)) {
            zettel = offered;
          } else {
            final base = NoteParsing.zettelId(v.createdAt ?? now);
            zettel = base;
            var n = 1;
            while (byZettel.containsKey(zettel)) {
              zettel = '$base-${n++}';
            }
          }
          final row = Note(
            id: id,
            zettelId: zettel,
            title: v.title.trim(),
            content: v.content,
            isArchived: v.archived,
            createdAt: v.createdAt ?? now,
            updatedAt: v.updatedAt ?? now,
          );
          await _db.into(_db.notes).insert(row);
          byId[row.id] = row;
          byZettel[row.zettelId] = row;
          if (row.title.trim().isNotEmpty) {
            byTitle[row.title.trim().toLowerCase()] = row;
          }
          created++;
        }
      }
    });

    await _repo.reindexAll();
    return VaultImportResult(created: created, updated: updated);
  }

  /// Re-reads Documents/LifeAssistVault — the path for edits made from
  /// the Files app (or files dropped there). Not available on web.
  Future<VaultImportResult> importFromFolder() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$folderName');
    if (!await dir.exists()) {
      return const VaultImportResult(created: 0, updated: 0);
    }
    final payloads = <VaultPayload>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.md') && !name.endsWith('.markdown')) continue;
      try {
        payloads.add(
          VaultPayload(name: name, content: await entity.readAsString()),
        );
      } catch (_) {
        // Skip unreadable files rather than fail the whole import.
      }
    }
    return importPayloads(payloads);
  }
}

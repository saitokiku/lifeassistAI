/// The vault file format: one Obsidian-compatible `.md` per note, YAML
/// frontmatter carrying identity so the round-trip is lossless. Pure
/// string work — no I/O — so it unit-tests directly.
///
/// A note serializes as:
///
/// ```
/// ---
/// id: <uuid>
/// title: "The exact title"
/// created: 2026-07-17T09:05:03.000
/// updated: 2026-07-17T09:41:12.000
/// tags: [focus, area/health]  # only when the body carries tags
/// archived: true              # only when true
/// ---
///
/// body markdown…
/// ```
///
/// `tags:` mirrors the body's `#tags` so Obsidian's Properties panel
/// and tag pane see them natively. The nonstandard `zettel:` key is no
/// longer written (the uuid `id:` is the round-trip identity) but is
/// still READ, so vaults exported by older builds import losslessly.
///
/// On import everything is optional: a plain Obsidian file with no
/// frontmatter (or with someone else's keys) still lands — the title
/// falls back to the filename, identity is minted fresh.
library;

import '../../../core/storage/app_database.dart';
import '../domain/note_parsing.dart';

/// One parsed `.md` file, pre-database: whatever identity the
/// frontmatter offered, plus title and body.
class VaultNote {
  const VaultNote({
    this.id,
    this.zettelId,
    required this.title,
    required this.content,
    this.archived = false,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? zettelId;
  final String title;
  final String content;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class ObsidianVault {
  ObsidianVault._();

  static final RegExp _frontmatterLine = RegExp(r'^([A-Za-z][\w-]*):\s*(.*)$');
  static final RegExp _unsafeFileChars = RegExp(r'[/\\:*?"<>|\x00-\x1f]');

  /// Serializes [note] into the full `.md` file text.
  static String serialize(Note note) {
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('id: ${note.id}')
      ..writeln('title: ${_quote(note.title.trim())}')
      ..writeln('created: ${note.createdAt.toIso8601String()}')
      ..writeln('updated: ${note.updatedAt.toIso8601String()}');
    final tags = NoteParsing.parse(note.content).tags;
    if (tags.isNotEmpty) buffer.writeln('tags: [${tags.join(', ')}]');
    if (note.isArchived) buffer.writeln('archived: true');
    buffer
      ..writeln('---')
      ..writeln();
    final body = note.content.trimRight();
    if (body.isNotEmpty) buffer.writeln(body);
    return buffer.toString();
  }

  /// The file name a note exports under: its title made filesystem-safe
  /// (Obsidian's convention — the filename IS the note's address), the
  /// zettel id when untitled.
  static String fileName(Note note) {
    var base = note.title.trim().replaceAll(_unsafeFileChars, '-');
    // Collapse runs, trim leading/trailing dots+spaces (Windows/Files).
    base = base
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^[\s.]+|[\s.]+$'), '');
    if (base.isEmpty) base = note.zettelId;
    if (base.length > 120) base = base.substring(0, 120).trimRight();
    return '$base.md';
  }

  /// Parses one file. [fileName] (with or without `.md`) supplies the
  /// title when the frontmatter doesn't.
  static VaultNote parse(String fileName, String raw) {
    var content = raw;
    final fields = <String, String>{};

    // Frontmatter: an opening '---' line, scalar `key: value` lines,
    // a closing '---'. Anything else means "no frontmatter" — the
    // whole file is body. Unknown keys are read and ignored.
    final normalized = raw.replaceAll('\r\n', '\n');
    if (normalized.startsWith('---\n')) {
      final close = normalized.indexOf('\n---', 4);
      if (close > 0) {
        final block = normalized.substring(4, close);
        for (final line in block.split('\n')) {
          final m = _frontmatterLine.firstMatch(line.trim());
          if (m != null) fields[m[1]!.toLowerCase()] = m[2]!.trim();
        }
        var bodyStart = close + 4; // past '\n---'
        // Swallow the newline after the closing fence and ONE blank line.
        if (bodyStart < normalized.length &&
            normalized[bodyStart] == '\n') {
          bodyStart++;
          if (bodyStart < normalized.length &&
              normalized[bodyStart] == '\n') {
            bodyStart++;
          }
        }
        content =
            bodyStart >= normalized.length ? '' : normalized.substring(bodyStart);
      }
    }

    var title = _unquote(fields['title'] ?? '');
    if (title.isEmpty) {
      title = fileName.replaceAll(RegExp(r'\.(md|markdown|txt)$'), '').trim();
    }

    final zettel = fields['zettel'] ?? fields['zettelid'];
    return VaultNote(
      id: _emptyToNull(fields['id']),
      zettelId: _emptyToNull(zettel),
      title: title,
      content: content.trimRight(),
      archived: fields['archived'] == 'true',
      createdAt: DateTime.tryParse(fields['created'] ?? ''),
      updatedAt: DateTime.tryParse(fields['updated'] ?? ''),
    );
  }

  static String? _emptyToNull(String? s) =>
      (s == null || s.isEmpty) ? null : s;

  /// YAML double-quoted scalar, escaping backslash and quote.
  static String _quote(String s) =>
      '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  static String _unquote(String s) {
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      return s
          .substring(1, s.length - 1)
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', r'\');
    }
    return s;
  }
}

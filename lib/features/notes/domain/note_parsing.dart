/// Pure parsing for the Zettelkasten: `[[wiki links]]` and `#tags` out
/// of markdown, plus the timestamp zettel id. No I/O — unit-tested
/// directly, shared by the repository (indexing) and the editor
/// (autocomplete + rendering).
library;

/// A `[[...]]` reference as written: the raw target plus the display
/// alias (`[[Target|shown text]]`). Heading refs (`[[Target#Section]]`)
/// resolve to the note, not the section — sections are a later layer.
class WikiLink {
  const WikiLink({required this.target, required this.display});

  /// The note title being referenced, trimmed, alias/heading stripped.
  final String target;

  /// What the reader sees: the alias if one was written, else [target].
  final String display;
}

/// Everything the indexer needs from one note body.
class ParsedNote {
  const ParsedNote({required this.links, required this.tags});

  /// Distinct link targets in order of first appearance
  /// (case-insensitively deduped — `[[Apple]]` and `[[apple]]` are one).
  final List<String> links;

  /// Distinct tags, lowercased, `#` stripped, in order of first
  /// appearance. Nested tags (`#area/health`) keep the slash.
  final List<String> tags;
}

class NoteParsing {
  NoteParsing._();

  /// `[[target]]`, `[[target|alias]]`, `[[target#heading]]`.
  static final RegExp wikiLinkPattern = RegExp(r'\[\[([^\[\]]+?)\]\]');

  /// `#tag` after start-of-line or whitespace. The lookahead demands at
  /// least one letter so `#123` (an issue number) is not a tag; block
  /// parsing keeps `# Heading` (hash + space) out of reach already, and
  /// the leading guard keeps URL fragments (`…/page#anchor`) out.
  static final RegExp tagPattern = RegExp(
    r'(?<=^|[\s(])#(?=[A-Za-z0-9_\-/]*[A-Za-z])([A-Za-z0-9_\-/]+)',
    multiLine: true,
  );

  static final RegExp _fencedCode = RegExp(r'```.*?```', dotAll: true);
  static final RegExp _inlineCode = RegExp(r'`[^`\n]*`');

  /// Splits a raw `[[...]]` body into target and display text.
  static WikiLink parseLinkBody(String raw) {
    var target = raw;
    String? alias;
    final pipe = target.indexOf('|');
    if (pipe >= 0) {
      alias = target.substring(pipe + 1).trim();
      target = target.substring(0, pipe);
    }
    final hash = target.indexOf('#');
    if (hash >= 0) target = target.substring(0, hash);
    target = target.trim();
    final display = (alias == null || alias.isEmpty) ? target : alias;
    return WikiLink(target: target, display: display);
  }

  /// One pass over a note body: distinct links + tags, code spans
  /// ignored (a `[[link]]` inside a code example is an example).
  static ParsedNote parse(String content) {
    final scannable = content
        .replaceAll(_fencedCode, ' ')
        .replaceAll(_inlineCode, ' ');

    final links = <String>[];
    final seenLinks = <String>{};
    for (final m in wikiLinkPattern.allMatches(scannable)) {
      final target = parseLinkBody(m[1]!).target;
      if (target.isEmpty) continue;
      if (seenLinks.add(target.toLowerCase())) links.add(target);
    }

    final tags = <String>[];
    final seenTags = <String>{};
    for (final m in tagPattern.allMatches(scannable)) {
      final tag = m[1]!.toLowerCase();
      if (seenTags.add(tag)) tags.add(tag);
    }

    return ParsedNote(links: links, tags: tags);
  }

  /// The Zettelkasten timestamp id: `yyyyMMddHHmmss`. Human-sortable,
  /// stable across renames — the permanent address of a thought.
  static String zettelId(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${at.year}${two(at.month)}${two(at.day)}'
        '${two(at.hour)}${two(at.minute)}${two(at.second)}';
  }
}

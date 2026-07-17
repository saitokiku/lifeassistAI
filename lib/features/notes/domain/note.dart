/// Note domain model: display helpers over the drift row.
library;

export '../../../core/storage/app_database.dart' show Note;

import '../../../core/storage/app_database.dart';

extension NoteX on Note {
  /// Every note deserves a name on screen, even before it has one.
  String get displayTitle => title.trim().isEmpty ? 'Untitled' : title.trim();

  /// First non-empty body line with markdown noise stripped — the list
  /// row's one-line preview.
  String get preview {
    for (final line in content.split('\n')) {
      final cleaned = line
          .replaceAll(RegExp(r'^[#>\-*\s]+'), '')
          .replaceAllMapped(
            RegExp(r'\[\[([^\[\]]+?)\]\]'),
            (m) {
              final body = m[1]!;
              final pipe = body.indexOf('|');
              return pipe >= 0 ? body.substring(pipe + 1) : body;
            },
          )
          .replaceAll(RegExp(r'[*_`]'), '')
          .trim();
      if (cleaned.isNotEmpty && cleaned != title.trim()) return cleaned;
    }
    return '';
  }
}

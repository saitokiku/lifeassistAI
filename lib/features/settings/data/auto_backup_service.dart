import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/preferences_service.dart';
import '../../../core/utils/date_utils.dart';
import 'backup_service.dart';

/// Weekly rolling safety copies in the app's documents folder.
///
/// Not a substitute for a real off-device export — it protects against
/// accidental resets and bad edits, not a lost phone. Keeps the newest
/// [keepCount] files and never blocks launch (fire-and-forget from the
/// shell; every failure is swallowed after a debug print).
class AutoBackupService {
  AutoBackupService(this._backup, this._prefs);

  final BackupService _backup;
  final PreferencesService _prefs;

  static const int keepCount = 4;
  static const Duration interval = Duration(days: 7);

  /// Newest safety copies kept per tag (pre-import, pre-reset).
  static const int safetyKeepCount = 2;

  Future<void> maybeRun({DateTime? now}) async {
    if (kIsWeb) return;
    final at = now ?? DateTime.now();
    try {
      final last = _prefs.lastAutoBackupAt;
      if (last != null && at.difference(last) < interval) return;

      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/backups');
      await folder.create(recursive: true);

      final json = await _backup.exportJson();
      final name = 'life_assist_auto_${AppDateUtils.dateKey(at)}.json';
      await File('${folder.path}/$name').writeAsString(json);

      // Rotate: names sort chronologically, newest last.
      final files = folder
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('life_assist_auto_'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final stale in files.skip(keepCount)) {
        await stale.delete();
      }

      await _prefs.setLastAutoBackupAt(at);
    } catch (e) {
      debugPrint('Auto-backup skipped: $e');
    }
  }

  /// Immediate safety copy before a destructive operation (import,
  /// reset) — the data about to be replaced must never have zero copies.
  /// Files land beside the weekly ones as
  /// `life_assist_<tag>_<stamp>.json`; the newest [safetyKeepCount] per
  /// tag are kept. Best-effort: failures are logged, never thrown, so a
  /// full disk can't block the operation the user asked for.
  Future<void> safetyCopy(String tag, {DateTime? now}) async {
    if (kIsWeb) return;
    final at = now ?? DateTime.now();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/backups');
      await folder.create(recursive: true);

      final json = await _backup.exportJson();
      final stamp =
          at.toIso8601String().replaceAll(':', '-').split('.').first;
      final prefix = 'life_assist_$tag';
      await File('${folder.path}/${prefix}_$stamp.json').writeAsString(json);

      final files = folder
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains(prefix))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final stale in files.skip(safetyKeepCount)) {
        await stale.delete();
      }
    } catch (e) {
      debugPrint('Safety copy ($tag) skipped: $e');
    }
  }
}

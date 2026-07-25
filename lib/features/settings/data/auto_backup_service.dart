import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/preferences_service.dart';
import '../../../core/utils/date_utils.dart';
import 'backup_service.dart';
import '../../../core/errors/error_log.dart';

/// Weekly rolling safety copies, plus on-demand copies taken before a
/// destructive operation.
///
/// Not a substitute for a real off-device export — it protects against
/// accidental resets and bad edits, not a lost phone. Keeps the newest
/// [keepCount] files and never blocks launch (fire-and-forget from the
/// shell; every failure is swallowed after a debug print).
///
/// **Stored in app support, not Documents.** These files are complete
/// unencrypted JSON dumps of the whole database. The app sets
/// `UIFileSharingEnabled` so the Obsidian vault is reachable in the
/// Files app, and iOS cannot scope that to one subfolder — so anything
/// under Documents is browsable and copyable by anyone who can unlock
/// the device. The vault is meant to be shared; a full financial and
/// journal dump is not. Users still get their own copies through
/// Settings → Export, which they place deliberately.
class AutoBackupService {
  AutoBackupService(this._backup, this._prefs);

  final BackupService _backup;
  final PreferencesService _prefs;

  /// Safety copies live beside the database, out of the Files-visible
  /// Documents tree.
  static Future<Directory> backupsDirectory() async {
    final root = await getApplicationSupportDirectory();
    return Directory('${root.path}/backups');
  }

  /// Moves a pre-existing `Documents/backups` folder into app support
  /// once, so old installs stop exposing full database dumps in Files.
  static Future<void> migrateOutOfDocuments() async {
    if (kIsWeb) return;
    try {
      final documents = await getApplicationDocumentsDirectory();
      final legacy = Directory('${documents.path}/backups');
      if (!legacy.existsSync()) return;
      final target = await backupsDirectory();
      await target.create(recursive: true);
      for (final file in legacy.listSync().whereType<File>()) {
        final name = file.uri.pathSegments.last;
        final moved = File('${target.path}/$name');
        if (!moved.existsSync()) await file.copy(moved.path);
        await file.delete();
      }
      if (legacy.listSync().isEmpty) await legacy.delete();
    } catch (e) {
      logError('backup.relocate', e);
    }
  }

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

      final folder = await backupsDirectory();
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
      logError('backup.auto', e);
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
      final folder = await backupsDirectory();
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
      logError('backup.safetyCopy.$tag', e);
    }
  }
}

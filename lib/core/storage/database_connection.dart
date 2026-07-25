import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../errors/error_log.dart';

/// The database file name (drift appends `.sqlite`).
const _databaseName = 'life_dashboard';

/// Opens the app database.
///
/// `drift_flutter` picks the right implementation per platform:
/// - iOS/Android/macOS/Windows/Linux: native SQLite file in the app
///   **support** directory (see below). The [web] options are ignored
///   entirely on these platforms.
/// - Web: an OPFS/IndexedDB-backed database using the committed
///   `web/drift_worker.js` worker and `web/sqlite3.wasm` module. Both are
///   required — without the `web` options drift throws at startup, so this
///   parameter must stay wired for the web build to launch at all.
///
/// **Why Application Support, not Documents.** drift_flutter's default
/// `databaseDirectory` is `getApplicationDocumentsDirectory()`, and this
/// app deliberately sets `UIFileSharingEnabled` +
/// `LSSupportsOpeningDocumentsInPlace` so the Obsidian vault is reachable
/// in the Files app. iOS cannot scope that to one subfolder, so the
/// default put the raw `life_dashboard.sqlite` — every transaction,
/// journal entry, and note — in a directory any user of the device (or a
/// trusted Mac) can browse and copy. Only the vault folder is meant to be
/// shared; the database is not.
QueryExecutor openAppDatabaseConnection() {
  return driftDatabase(
    name: _databaseName,
    native: DriftNativeOptions(databaseDirectory: appDatabaseDirectory),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}

/// Where the database lives: the app support directory, which is backed
/// up with the app but never exposed through file sharing.
Future<Directory> appDatabaseDirectory() => getApplicationSupportDirectory();

/// Moves a pre-existing database out of the Files-visible Documents
/// directory into app support, once, before the database is opened.
///
/// Installs that predate the move already have their data in Documents;
/// leaving it there would keep it exposed AND strand it (the app would
/// open a fresh empty file next to it). Copies the main file plus its
/// `-wal`/`-shm` siblings, then removes the originals. Best-effort: if
/// anything fails the originals stay put and the app opens whatever is
/// at the new path.
Future<void> migrateDatabaseOutOfDocuments() async {
  if (kIsWeb) return;
  try {
    final documents = await getApplicationDocumentsDirectory();
    final support = await appDatabaseDirectory();
    final legacy = File('${documents.path}/$_databaseName.sqlite');
    if (!legacy.existsSync()) return;
    final target = File('${support.path}/$_databaseName.sqlite');
    if (target.existsSync()) return; // already migrated; leave both alone

    await support.create(recursive: true);
    for (final suffix in ['', '-wal', '-shm']) {
      final from = File('${legacy.path}$suffix');
      if (!from.existsSync()) continue;
      await from.copy('${target.path}$suffix');
    }
    // Only delete once every copy landed.
    for (final suffix in ['', '-wal', '-shm']) {
      final from = File('${legacy.path}$suffix');
      if (from.existsSync()) await from.delete();
    }
  } catch (e) {
    logError('storage.relocate', e);
  }
}

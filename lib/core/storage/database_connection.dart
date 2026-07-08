import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens the app database.
///
/// `drift_flutter` picks the right implementation per platform:
/// - iOS/Android/macOS/Windows/Linux: native SQLite file in the app
///   documents directory (via sqlite3_flutter_libs + path_provider).
///   The [web] options below are ignored entirely on these platforms.
/// - Web: an OPFS/IndexedDB-backed database using the committed
///   `web/drift_worker.js` worker and `web/sqlite3.wasm` module. Both are
///   required — without the `web` options drift throws at startup, so this
///   parameter must stay wired for the web build to launch at all.
QueryExecutor openAppDatabaseConnection() {
  return driftDatabase(
    name: 'life_dashboard',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}

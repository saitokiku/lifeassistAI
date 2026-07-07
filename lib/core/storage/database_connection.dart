import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens the app database.
///
/// `drift_flutter` picks the right implementation per platform:
/// - iOS/Android/macOS/Windows/Linux: native SQLite file in the app
///   documents directory (via sqlite3_flutter_libs + path_provider).
/// - Web: IndexedDB/OPFS-backed storage when `sqlite3.wasm` and
///   `drift_worker.js` are present in `web/`; otherwise drift falls back
///   and logs a warning. See docs/release_ios.md for the web caveat.
QueryExecutor openAppDatabaseConnection() {
  return driftDatabase(name: 'life_dashboard');
}

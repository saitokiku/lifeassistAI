import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../storage/app_database.dart';
import 'bridge_paths.dart';

/// Keeps `entities.json` — the app's nouns, mirrored for the Swift side —
/// in sync with the database.
///
/// Siri's EntityQueries (BackgroundIntents.swift) resolve "Groceries" or
/// "Deep work" against this file without ever starting the Flutter engine
/// or reading the drift schema. A stale mirror only degrades Siri's
/// suggestions, never correctness: queue records carry the raw spoken
/// name too, and the drain re-resolves against live data.
///
/// Envelope (version bumps on shape changes; Swift ignores unknown keys):
/// ```json
/// {"v":1, "generatedAt":"…", "budgetCategories":[{"id","name"}],
///  "timeBudgets":[{"id","name","kind"}], "habits":[{"id","name"}]}
/// ```
class EntityMirrorService {
  EntityMirrorService(this._db, this._paths);

  static const int version = 1;

  final AppDatabase _db;
  final BridgePaths _paths;

  StreamSubscription<void>? _sub;
  Timer? _debounce;
  Future<void> _writing = Future.value();

  /// Starts watching and writes once immediately (covers first launch,
  /// version mismatch, and post-import states).
  Future<void> start() async {
    await writeNow();
    _sub = _db
        .tableUpdates(TableUpdateQuery.onAllTables([
          _db.budgetCategories,
          _db.timeBudgets,
          _db.habits,
        ]))
        .listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), writeNow);
    });
  }

  Future<void> stop() async {
    _debounce?.cancel();
    await _sub?.cancel();
    _sub = null;
  }

  /// Serializes writes so a rewrite never interleaves with itself; each
  /// write is atomic on disk (tmp + rename).
  Future<void> writeNow() {
    return _writing = _writing.then((_) => _write()).catchError((_) {
      // A failed mirror write must never take the app down; Swift treats
      // a missing/unreadable file as "no suggestions".
    });
  }

  Future<void> _write() async {
    final categories = await _db.select(_db.budgetCategories).get();
    final budgets = await _db.select(_db.timeBudgets).get();
    final habits = await (_db.select(_db.habits)
          ..where((t) => t.isArchived.equals(false)))
        .get();

    final payload = <String, dynamic>{
      'v': version,
      'generatedAt': DateTime.now().toIso8601String(),
      'budgetCategories': [
        for (final c in categories) {'id': c.id, 'name': c.name},
      ],
      'timeBudgets': [
        for (final b in budgets) {'id': b.id, 'name': b.name, 'kind': b.kind},
      ],
      'habits': [
        for (final h in habits) {'id': h.id, 'name': h.name},
      ],
    };

    await _paths.root.create(recursive: true);
    final tmp = File('${_paths.entitiesFile.path}.tmp');
    await tmp.writeAsString(jsonEncode(payload), flush: true);
    await tmp.rename(_paths.entitiesFile.path);
  }
}

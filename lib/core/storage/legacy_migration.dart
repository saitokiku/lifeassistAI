import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

/// Rewrites pre-v2 ("Kaizen era") data into the universal main-goal shape.
///
/// Before v2 the app was built around one hardcoded goal called Kaizen:
/// a `kaizen` time-budget kind, a `kaizenExperiment` reminder type, and the
/// growth metric + daily experiment loop living on a dedicated Kaizen tab.
/// v2 makes the goal user-defined. This migration:
///
/// 1. Rewrites legacy enum values stored in rows (`kaizen` → `goal`,
///    `kaizenExperiment` → `dailyAction`).
/// 2. If the database contains Kaizen-era activity but no main goal yet,
///    creates one named "Kaizen" — preserving the original owner's goal as
///    real user data instead of a product concept.
///
/// Idempotent and cheap; runs on every launch after seeding, and after a
/// backup import (which may restore a v1 envelope).
class LegacyMigration {
  LegacyMigration(this._db);

  final AppDatabase _db;

  static const String legacyGoalTitle = 'Kaizen';

  Future<void> run({DateTime? now}) async {
    final at = now ?? DateTime.now();
    await _db.transaction(() async {
      await _rewriteLegacyKinds();
      await _deriveMainGoal(at);
    });
  }

  Future<void> _rewriteLegacyKinds() async {
    await (_db.update(_db.timeBudgets)..where((t) => t.kind.equals('kaizen')))
        .write(const TimeBudgetsCompanion(kind: Value('goal')));
    await (_db.update(_db.reminders)
          ..where((t) => t.type.equals('kaizenExperiment')))
        .write(const RemindersCompanion(type: Value('dailyAction')));
  }

  /// A v1 database always carried Kaizen artifacts (a growth metric was
  /// seeded on first launch), so their presence + no main goal means this
  /// is an upgrade, not a fresh install.
  Future<void> _deriveMainGoal(DateTime at) async {
    final existing = await (_db.select(_db.mainGoals)..limit(1)).get();
    if (existing.isNotEmpty) return;

    final metrics = await (_db.select(_db.growthMetrics)..limit(1)).get();
    final experiments =
        await (_db.select(_db.dailyExperiments)..limit(1)).get();
    if (metrics.isEmpty && experiments.isEmpty) return;

    await _db.into(_db.mainGoals).insert(MainGoal(
          id: const Uuid().v4(),
          title: legacyGoalTitle,
          why: '',
          targetDate: null,
          status: 'active',
          createdAt: at,
          updatedAt: at,
          completedAt: null,
        ));
  }
}

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Persistence for goals, freedom targets, and identity statements.
class IdentityRepository {
  IdentityRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // --- Goals ----------------------------------------------------------------

  Stream<List<Goal>> watchGoals() => (_db.select(_db.goals)
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();

  Future<void> createGoal({
    required String title,
    String? description,
    String? metricName,
    required double currentValue,
    required double targetValue,
    DateTime? targetDate,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.goals).insert(Goal(
          id: _uuid.v4(),
          title: title,
          description: description,
          metricName: metricName,
          currentValue: currentValue,
          targetValue: targetValue,
          targetDate:
              targetDate == null ? null : AppDateUtils.dateKey(targetDate),
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> updateGoal(Goal goal) => _db.update(_db.goals).replace(
        goal.copyWith(updatedAt: DateTime.now()),
      );

  Future<void> deleteGoal(String id) =>
      (_db.delete(_db.goals)..where((t) => t.id.equals(id))).go();

  // --- Freedom targets ------------------------------------------------------

  Stream<List<FreedomTarget>> watchFreedomTargets() =>
      (_db.select(_db.freedomTargets)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<void> createFreedomTarget({
    required String title,
    String? description,
    required double targetMonthlyPassiveIncome,
    required double targetLiquidNetWorth,
    DateTime? targetDate,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.freedomTargets).insert(FreedomTarget(
          id: _uuid.v4(),
          title: title,
          description: description,
          targetMonthlyPassiveIncome: targetMonthlyPassiveIncome,
          targetLiquidNetWorth: targetLiquidNetWorth,
          currentMonthlyPassiveIncome: 0,
          currentLiquidNetWorth: 0,
          targetDate:
              targetDate == null ? null : AppDateUtils.dateKey(targetDate),
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> updateFreedomTarget(FreedomTarget target) =>
      _db.update(_db.freedomTargets).replace(
            target.copyWith(updatedAt: DateTime.now()),
          );

  Future<void> deleteFreedomTarget(String id) =>
      (_db.delete(_db.freedomTargets)..where((t) => t.id.equals(id))).go();

  // --- Identity statements --------------------------------------------------

  Stream<List<IdentityStatement>> watchStatements() =>
      (_db.select(_db.identityStatements)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<void> createStatement(String content) async {
    final existing = await _db.select(_db.identityStatements).get();
    await _db.into(_db.identityStatements).insert(IdentityStatement(
          id: _uuid.v4(),
          content: content,
          sortOrder: existing.length,
        ));
  }

  Future<void> updateStatement(IdentityStatement statement) =>
      _db.update(_db.identityStatements).replace(statement);

  Future<void> deleteStatement(String id) =>
      (_db.delete(_db.identityStatements)..where((t) => t.id.equals(id))).go();
}

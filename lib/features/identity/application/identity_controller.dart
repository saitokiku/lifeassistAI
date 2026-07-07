import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../settings/application/settings_controller.dart';
import '../data/identity_repository.dart';
import 'identity_state.dart';

final identityRepositoryProvider = Provider<IdentityRepository>(
  (ref) => IdentityRepository(ref.watch(databaseProvider)),
);

final goalsProvider = StreamProvider<List<Goal>>(
  (ref) => ref.watch(identityRepositoryProvider).watchGoals(),
);

final freedomTargetsProvider = StreamProvider<List<FreedomTarget>>(
  (ref) => ref.watch(identityRepositoryProvider).watchFreedomTargets(),
);

final identityStatementsProvider = StreamProvider<List<IdentityStatement>>(
  (ref) => ref.watch(identityRepositoryProvider).watchStatements(),
);

final identityStateProvider = Provider<IdentityState?>((ref) {
  final statements = ref.watch(identityStatementsProvider).valueOrNull;
  final goals = ref.watch(goalsProvider).valueOrNull;
  final targets = ref.watch(freedomTargetsProvider).valueOrNull;
  final settings = ref.watch(settingsProvider).valueOrNull;
  if (statements == null || goals == null || targets == null) return null;

  return IdentityState(
    statements: statements,
    goals: goals,
    freedomTargets: targets,
    philosophyText: settings?.philosophyText ?? '',
  );
});

class IdentityController {
  IdentityController(this._repo);

  final IdentityRepository _repo;

  Future<void> createGoal({
    required String title,
    String? description,
    String? metricName,
    required double currentValue,
    required double targetValue,
    DateTime? targetDate,
  }) =>
      _repo.createGoal(
        title: title,
        description: description,
        metricName: metricName,
        currentValue: currentValue,
        targetValue: targetValue,
        targetDate: targetDate,
      );

  Future<void> updateGoal(Goal goal) => _repo.updateGoal(goal);

  Future<void> deleteGoal(String id) => _repo.deleteGoal(id);

  Future<void> createFreedomTarget({
    required String title,
    String? description,
    required double targetMonthlyPassiveIncome,
    required double targetLiquidNetWorth,
    DateTime? targetDate,
  }) =>
      _repo.createFreedomTarget(
        title: title,
        description: description,
        targetMonthlyPassiveIncome: targetMonthlyPassiveIncome,
        targetLiquidNetWorth: targetLiquidNetWorth,
        targetDate: targetDate,
      );

  Future<void> updateFreedomTarget(FreedomTarget target) =>
      _repo.updateFreedomTarget(target);

  Future<void> deleteFreedomTarget(String id) => _repo.deleteFreedomTarget(id);

  Future<void> createStatement(String content) => _repo.createStatement(content);

  Future<void> updateStatement(IdentityStatement statement) =>
      _repo.updateStatement(statement);

  Future<void> deleteStatement(String id) => _repo.deleteStatement(id);
}

final identityControllerProvider = Provider<IdentityController>(
  (ref) => IdentityController(ref.watch(identityRepositoryProvider)),
);

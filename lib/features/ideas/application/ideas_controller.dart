import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../data/ideas_repository.dart';
import 'ideas_state.dart';

final ideasRepositoryProvider = Provider<IdeasRepository>(
  (ref) => IdeasRepository(ref.watch(databaseProvider)),
);

final ideasProvider = StreamProvider<List<ParkedIdea>>(
  (ref) => ref.watch(ideasRepositoryProvider).watchIdeas(),
);

final ideasStateProvider = Provider<IdeasState?>((ref) {
  final now = readNow(ref);
  final ideas = ref.watch(ideasProvider).valueOrNull;
  if (ideas == null) return null;
  return IdeasState(ideas: ideas, today: AppDateUtils.dateOnly(now));
});

class IdeasController {
  IdeasController(this._repo);

  final IdeasRepository _repo;

  Future<void> captureIdea({
    required String title,
    String? description,
    String? category,
    String? whyTempting,
    String? potentialValue,
    required bool helpsMainGoal,
  }) =>
      _repo.captureIdea(
        title: title,
        description: description,
        category: category,
        whyTempting: whyTempting,
        potentialValue: potentialValue,
        helpsMainGoal: helpsMainGoal,
      );

  Future<void> updateIdea(ParkedIdea idea) => _repo.updateIdea(idea);

  Future<void> setDecision(String id, String decision) =>
      _repo.setDecision(id, decision);

  Future<void> deleteIdea(String id) => _repo.deleteIdea(id);
}

final ideasControllerProvider = Provider<IdeasController>(
  (ref) => IdeasController(ref.watch(ideasRepositoryProvider)),
);

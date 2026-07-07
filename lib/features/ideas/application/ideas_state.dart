import '../domain/idea_decision.dart';
import '../domain/parked_idea.dart';

/// Display-ready parking lot state.
class IdeasState {
  const IdeasState({required this.ideas, required this.today});

  final List<ParkedIdea> ideas; // newest first
  final DateTime today;

  List<ParkedIdea> get undecided =>
      ideas.where((i) => i.decisionEnum == IdeaDecision.undecided).toList();

  List<ParkedIdea> get cooling =>
      undecided.where((i) => i.isCooling(today)).toList();

  /// Undecided ideas whose cooling has passed — due for a verdict.
  List<ParkedIdea> get dueForReview =>
      undecided.where((i) => !i.isCooling(today)).toList();

  int get parkedCount => undecided.length;
}

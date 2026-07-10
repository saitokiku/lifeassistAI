import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/features/ideas/application/ideas_state.dart';
import 'package:life_dashboard/features/ideas/domain/idea_decision.dart';
import 'package:life_dashboard/features/ideas/domain/parked_idea.dart';

ParkedIdea idea({
  required String captured,
  required String review,
  bool helpsGoal = false,
  String decision = 'undecided',
  String id = 'i',
}) =>
    ParkedIdea(
      id: id,
      title: 'Idea',
      description: null,
      category: null,
      whyTempting: null,
      potentialValue: null,
      dateCaptured: captured,
      reviewDate: review,
      decision: decision,
      helpsMainGoal: helpsGoal,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  final today = DateTime(2026, 7, 7);

  group('7-day cooling rule', () {
    test('idea is cooling until its review date', () {
      final cooling =
          idea(captured: '2026-07-05', review: '2026-07-12');
      expect(cooling.isCooling(today), isTrue);
      expect(cooling.daysUntilReview(today), 5);
      expect(cooling.canActivate(today), isFalse);
    });

    test('cooling ends on the review date', () {
      final due = idea(captured: '2026-06-30', review: '2026-07-07');
      expect(due.isCooling(today), isFalse);
      expect(due.canActivate(today), isTrue);
    });

    test('directly-helps-the-goal bypasses cooling', () {
      final helper = idea(
        captured: '2026-07-07',
        review: '2026-07-14',
        helpsGoal: true,
      );
      expect(helper.isCooling(today), isTrue);
      expect(helper.canActivate(today), isTrue);
    });
  });

  group('IdeasState buckets', () {
    test('splits cooling, due-for-review, and decided', () {
      final state = IdeasState(
        today: today,
        ideas: [
          idea(id: 'cooling', captured: '2026-07-05', review: '2026-07-12'),
          idea(id: 'due', captured: '2026-06-28', review: '2026-07-05'),
          idea(
            id: 'done',
            captured: '2026-06-01',
            review: '2026-06-08',
            decision: 'integrate',
          ),
        ],
      );
      expect(state.parkedCount, 2); // undecided only
      expect(state.cooling.single.id, 'cooling');
      expect(state.dueForReview.single.id, 'due');
    });
  });

  group('Decisions', () {
    test('parse round-trips', () {
      for (final d in IdeaDecision.values) {
        expect(IdeaDecision.parse(d.name), d);
      }
      expect(IdeaDecision.parse('garbage'), IdeaDecision.undecided);
    });
  });
}

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Persistence for the idea parking lot.
class IdeasRepository {
  IdeasRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<ParkedIdea>> watchIdeas() => (_db.select(_db.parkedIdeas)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  /// Captures an idea. Review date is automatically set 7 days out.
  Future<void> captureIdea({
    required String title,
    String? description,
    String? category,
    String? whyTempting,
    String? potentialValue,
    required bool directlyHelpsKaizenThisWeek,
    DateTime? capturedOn,
  }) async {
    final now = DateTime.now();
    final captured = AppDateUtils.dateOnly(capturedOn ?? now);
    await _db.into(_db.parkedIdeas).insert(ParkedIdea(
          id: _uuid.v4(),
          title: title,
          description: description,
          category: category,
          whyTempting: whyTempting,
          potentialValue: potentialValue,
          dateCaptured: AppDateUtils.dateKey(captured),
          reviewDate: AppDateUtils.dateKey(
            captured.add(const Duration(days: AppConstants.ideaCoolingDays)),
          ),
          decision: 'undecided',
          directlyHelpsKaizenThisWeek: directlyHelpsKaizenThisWeek,
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> updateIdea(ParkedIdea idea) =>
      _db.update(_db.parkedIdeas).replace(
            idea.copyWith(updatedAt: DateTime.now()),
          );

  Future<void> setDecision(String id, String decision) =>
      (_db.update(_db.parkedIdeas)..where((t) => t.id.equals(id)))
          .write(ParkedIdeasCompanion(
        decision: Value(decision),
        updatedAt: Value(DateTime.now()),
      ));

  Future<void> deleteIdea(String id) =>
      (_db.delete(_db.parkedIdeas)..where((t) => t.id.equals(id))).go();
}

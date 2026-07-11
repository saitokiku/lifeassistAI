import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Persistence for weekly reviews (one row per Monday-keyed week).
class ReviewRepository {
  ReviewRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<WeeklyReview>> watchReviews({int limit = 26}) =>
      (_db.select(_db.weeklyReviews)
            ..orderBy([(t) => OrderingTerm.desc(t.weekStart)])
            ..limit(limit))
          .watch();

  Stream<WeeklyReview?> watchForWeek(DateTime weekOf) =>
      (_db.select(_db.weeklyReviews)
            ..where((t) => t.weekStart
                .equals(AppDateUtils.dateKey(AppDateUtils.startOfWeek(weekOf)))))
          .watchSingleOrNull();

  Future<void> upsertReview({
    required DateTime weekOf,
    required String reflection,
    required String emphasis,
  }) async {
    final weekKey =
        AppDateUtils.dateKey(AppDateUtils.startOfWeek(weekOf));
    final existing = await (_db.select(_db.weeklyReviews)
          ..where((t) => t.weekStart.equals(weekKey)))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.weeklyReviews)
            ..where((t) => t.id.equals(existing.id)))
          .write(WeeklyReviewsCompanion(
        reflection: Value(reflection),
        emphasis: Value(emphasis),
      ));
    } else {
      await _db.into(_db.weeklyReviews).insert(WeeklyReview(
            id: _uuid.v4(),
            weekStart: weekKey,
            reflection: reflection,
            emphasis: emphasis,
            createdAt: DateTime.now(),
          ));
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../data/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(ref.watch(databaseProvider)),
);

/// This week's review row, if written. Rolls over with the day.
final currentWeekReviewProvider = StreamProvider<WeeklyReview?>((ref) {
  final today = readToday(ref);
  return ref.watch(reviewRepositoryProvider).watchForWeek(today);
});

/// Recent reviews, newest first.
final recentReviewsProvider = StreamProvider<List<WeeklyReview>>(
  (ref) => ref.watch(reviewRepositoryProvider).watchReviews(),
);

class ReviewController {
  ReviewController(this._repo);

  final ReviewRepository _repo;

  Future<void> saveReview({
    required DateTime weekOf,
    required String reflection,
    required String emphasis,
  }) =>
      _repo.upsertReview(
        weekOf: weekOf,
        reflection: reflection,
        emphasis: emphasis,
      );
}

final reviewControllerProvider = Provider<ReviewController>(
  (ref) => ReviewController(ref.watch(reviewRepositoryProvider)),
);

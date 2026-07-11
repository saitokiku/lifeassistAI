/// Parked idea domain model and anti-diffusion rules.
library;

export '../../../core/storage/app_database.dart' show ParkedIdea;

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import 'idea_decision.dart';

extension ParkedIdeaX on ParkedIdea {
  IdeaDecision get decisionEnum => IdeaDecision.parse(decision);

  DateTime get reviewDateTime => AppDateUtils.parseDateKey(reviewDate);

  /// Cooling off until the review date. Curiosity captured, not chased.
  bool isCooling(DateTime today) =>
      AppDateUtils.dateOnly(today).isBefore(reviewDateTime);

  int daysUntilReview(DateTime today) =>
      AppDateUtils.daysUntil(reviewDateTime, from: today);

  /// An idea may be activated (worked on) only when it directly helps
  /// the main goal right now, or its 7-day cooling period has passed.
  bool canActivate(DateTime today) => helpsMainGoal || !isCooling(today);
}

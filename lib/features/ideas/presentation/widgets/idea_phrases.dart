import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/idea_decision.dart';
import '../../domain/parked_idea.dart';

/// Humanized phrasing for the parking lot. Ideas age in days, not ISO
/// strings — no raw `yyyy-MM-dd` ever reaches the user.
class IdeaPhrases {
  IdeaPhrases._();

  /// 'parked today' / 'parked yesterday' / 'parked 9 days ago'
  static String parked(ParkedIdea idea, DateTime today) {
    final captured = AppDateUtils.parseDateKey(idea.dateCaptured);
    final days = -AppDateUtils.daysUntil(captured, from: today);
    if (days <= 0) return 'parked today';
    if (days == 1) return 'parked yesterday';
    return 'parked $days days ago';
  }

  /// Once cooling has passed: 'due today' / 'due yesterday' /
  /// 'due 3 days ago'. Overdue verdicts say how overdue.
  static String due(ParkedIdea idea, DateTime today) {
    final overdue = -idea.daysUntilReview(today);
    if (overdue <= 0) return 'due today';
    if (overdue == 1) return 'due yesterday';
    return 'due $overdue days ago';
  }

  /// While cooling: 'verdict tomorrow' / 'verdict in 4 days'.
  static String verdictIn(ParkedIdea idea, DateTime today) {
    final left = idea.daysUntilReview(today);
    if (left <= 0) return 'verdict today';
    if (left == 1) return 'verdict tomorrow';
    return 'verdict in $left days';
  }

  /// 0..1 progress through the cooling window (elapsed days / window).
  static double coolingProgress(ParkedIdea idea, DateTime today) {
    final captured = AppDateUtils.parseDateKey(idea.dateCaptured);
    var total = AppDateUtils.daysUntil(idea.reviewDateTime, from: captured);
    if (total <= 0) total = AppConstants.ideaCoolingDays;
    final left = idea.daysUntilReview(today);
    return ((total - left) / total).clamp(0.0, 1.0);
  }
}

/// StatusLevel mapping for verdict badges — the pill-level twin of
/// [IdeaDecision.color], kept here because the domain layer owns colors,
/// not badge levels.
extension IdeaDecisionLevel on IdeaDecision {
  StatusLevel get level => switch (this) {
        IdeaDecision.integrate => StatusLevel.aligned,
        IdeaDecision.later => StatusLevel.watch,
        IdeaDecision.ignore => StatusLevel.critical,
        IdeaDecision.undecided => StatusLevel.neutral,
      };
}

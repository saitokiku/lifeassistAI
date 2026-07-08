import '../core/utils/score_utils.dart';
import '../core/theme/app_colors.dart';

/// Display-layer status mapping.
///
/// ScoreUtils' fixed thresholds (35h/25h) are calibrated to the default 42h
/// Kaizen target and are locked by tests. When the user edits their target,
/// fixed cutoffs contradict the progress bar (full green bar, red badge).
/// This mapper keeps the same *ratios* (35/42 ≈ 0.83, 25/42 ≈ 0.6) but
/// anchors them to the user's actual target, so badges and bars always agree.
/// With the default target the results are identical to ScoreUtils.
class StatusDisplay {
  StatusDisplay._();

  static const double _alignedRatio = 35 / 42;
  static const double _watchRatio = 25 / 42;

  /// Status for hours-against-target metrics (Kaizen hours).
  static StatusLevel hoursStatus(double hours, double target) {
    if (target <= 0) return ScoreUtils.kaizenHoursStatus(hours);
    final ratio = hours / target;
    if (ratio >= _alignedRatio) return StatusLevel.aligned;
    if (ratio >= _watchRatio) return StatusLevel.watch;
    return StatusLevel.critical;
  }

  /// Label matching [hoursStatus], using the app's status vocabulary.
  static String hoursLabel(double hours, double target) =>
      switch (hoursStatus(hours, target)) {
        StatusLevel.aligned => 'Aligned',
        StatusLevel.watch => 'Watch',
        _ => 'Drifting',
      };
}

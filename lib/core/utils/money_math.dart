/// Money projection math. Pure functions, unit tested.
class MoneyMath {
  MoneyMath._();

  /// Days that must elapse before a straight-line projection means
  /// anything. Rent and other big monthly charges land on day 1, and
  /// `spend / 1 * 31` turns a single $1,500 charge into $46,500 of
  /// "projected" spending — which used to fire a critical money alert
  /// and hijack the Up Next card for the first days of every month.
  static const int minDaysForProjection = 4;

  /// Whether a straight-line projection is meaningful yet.
  static bool projectionIsMeaningful(int dayOfMonth) =>
      dayOfMonth >= minDaysForProjection;

  /// Straight-line projection of monthly spend from month-to-date spend.
  ///
  /// Early in the month the extrapolation is dominated by whichever
  /// large charges happen to have landed, so until
  /// [minDaysForProjection] the projection is blended toward a
  /// full-month baseline: weight the extrapolation by how much of the
  /// month has actually elapsed. Callers that need to know whether the
  /// number is trustworthy should ask [projectionIsMeaningful].
  static double projectedSpend({
    required double spendSoFar,
    required int dayOfMonth,
    required int daysInMonth,
  }) {
    if (dayOfMonth <= 0 || daysInMonth <= 0) return spendSoFar;
    final linear = spendSoFar / dayOfMonth * daysInMonth;
    if (dayOfMonth >= minDaysForProjection) return linear;
    // Day 1 of 31: weight 1/31 on the wild extrapolation, the rest on
    // what has actually been spent. By day 4 the blend is gone.
    final elapsed = dayOfMonth / daysInMonth;
    return spendSoFar + (linear - spendSoFar) * elapsed;
  }

  static double projectedSurplus({
    required double monthlyNetIncome,
    required double projectedSpend,
  }) =>
      monthlyNetIncome - projectedSpend;

  static double annualSavingsProjection(double projectedSurplus) =>
      projectedSurplus * 12;

  /// How far through the month we are, 0..1. Used for pace checks.
  static double monthPaceFraction({
    required int dayOfMonth,
    required int daysInMonth,
  }) {
    if (daysInMonth <= 0) return 0;
    return (dayOfMonth / daysInMonth).clamp(0.0, 1.0);
  }

  /// Whether spending is within the target pace for this point in the month:
  /// projected surplus at or above the low target.
  static bool withinTargetPace({
    required double projectedSurplus,
    required double targetSurplusLow,
  }) =>
      projectedSurplus >= targetSurplusLow;
}

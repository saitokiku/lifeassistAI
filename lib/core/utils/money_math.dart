/// Money projection math. Pure functions, unit tested.
class MoneyMath {
  MoneyMath._();

  /// Straight-line projection of monthly spend from month-to-date spend.
  /// Guards day 0 / invalid inputs by returning the spend so far.
  static double projectedSpend({
    required double spendSoFar,
    required int dayOfMonth,
    required int daysInMonth,
  }) {
    if (dayOfMonth <= 0 || daysInMonth <= 0) return spendSoFar;
    return spendSoFar / dayOfMonth * daysInMonth;
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

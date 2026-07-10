/// Typed view over the key-value settings table.
class UserSettings {
  const UserSettings({
    required this.displayName,
    required this.monthlyNetIncome,
    required this.targetSurplusLow,
    required this.targetSurplusHigh,
    required this.birthday,
    required this.retirementAnnualTarget,
    required this.retirementContributed,
    required this.brokerageBalance,
    required this.savingsBalance,
    required this.philosophyText,
    required this.dashboardAreas,
  });

  /// What the app calls the user; empty until they share a name.
  final String displayName;

  final double monthlyNetIncome;
  final double targetSurplusLow;
  final double targetSurplusHigh;
  final DateTime? birthday;
  final double retirementAnnualTarget;
  final double retirementContributed;
  final double brokerageBalance;
  final double savingsBalance;

  /// A short personal line shown on Today; empty until the user writes one.
  final String philosophyText;

  /// Which optional areas appear on the Today screen.
  final Set<DashboardArea> dashboardAreas;

  /// Income of 0 means money setup hasn't happened yet — screens invite
  /// setup instead of projecting from nothing.
  bool get hasIncome => monthlyNetIncome > 0;

  bool showsArea(DashboardArea area) => dashboardAreas.contains(area);

  UserSettings copyWith({
    String? displayName,
    double? monthlyNetIncome,
    double? targetSurplusLow,
    double? targetSurplusHigh,
    DateTime? birthday,
    bool clearBirthday = false,
    double? retirementAnnualTarget,
    double? retirementContributed,
    double? brokerageBalance,
    double? savingsBalance,
    String? philosophyText,
    Set<DashboardArea>? dashboardAreas,
  }) =>
      UserSettings(
        displayName: displayName ?? this.displayName,
        monthlyNetIncome: monthlyNetIncome ?? this.monthlyNetIncome,
        targetSurplusLow: targetSurplusLow ?? this.targetSurplusLow,
        targetSurplusHigh: targetSurplusHigh ?? this.targetSurplusHigh,
        birthday: clearBirthday ? null : (birthday ?? this.birthday),
        retirementAnnualTarget:
            retirementAnnualTarget ?? this.retirementAnnualTarget,
        retirementContributed:
            retirementContributed ?? this.retirementContributed,
        brokerageBalance: brokerageBalance ?? this.brokerageBalance,
        savingsBalance: savingsBalance ?? this.savingsBalance,
        philosophyText: philosophyText ?? this.philosophyText,
        dashboardAreas: dashboardAreas ?? this.dashboardAreas,
      );
}

/// Optional Today-screen modules the user can turn on or off.
enum DashboardArea {
  money,
  time,
  habits,
  ideas;

  static const Set<DashboardArea> all = {money, time, habits, ideas};

  /// Sentinel stored when the user turned every module off — an absent or
  /// blank value means "never chosen", which defaults to everything.
  static const String _noneSentinel = 'none';

  static DashboardArea? tryParse(String raw) {
    for (final area in values) {
      if (area.name == raw) return area;
    }
    return null;
  }

  /// Parses the stored comma-separated list; absent/blank means everything.
  static Set<DashboardArea> parseList(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return all;
    if (trimmed == _noneSentinel) return const {};
    return {
      for (final part in trimmed.split(','))
        if (tryParse(part.trim()) case final area?) area,
    };
  }

  static String encode(Set<DashboardArea> areas) =>
      areas.isEmpty ? _noneSentinel : areas.map((a) => a.name).join(',');

  String get label => switch (this) {
        DashboardArea.money => 'Money',
        DashboardArea.time => 'Time',
        DashboardArea.habits => 'Habits',
        DashboardArea.ideas => 'Ideas',
      };

  String get description => switch (this) {
        DashboardArea.money => 'Spending, budget, and surplus',
        DashboardArea.time => 'Weekly hours and downtime',
        DashboardArea.habits => 'Daily check-ins',
        DashboardArea.ideas => 'A parking lot for new ideas',
      };
}

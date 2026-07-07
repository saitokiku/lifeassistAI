/// Typed view over the key-value settings table.
class UserSettings {
  const UserSettings({
    required this.monthlyNetIncome,
    required this.targetSurplusLow,
    required this.targetSurplusHigh,
    required this.birthday,
    required this.rothIraAnnualTarget,
    required this.rothIraContributed,
    required this.brokerageBalance,
    required this.savingsBalance,
    required this.philosophyText,
  });

  final double monthlyNetIncome;
  final double targetSurplusLow;
  final double targetSurplusHigh;
  final DateTime? birthday;
  final double rothIraAnnualTarget;
  final double rothIraContributed;
  final double brokerageBalance;
  final double savingsBalance;
  final String philosophyText;

  UserSettings copyWith({
    double? monthlyNetIncome,
    double? targetSurplusLow,
    double? targetSurplusHigh,
    DateTime? birthday,
    bool clearBirthday = false,
    double? rothIraAnnualTarget,
    double? rothIraContributed,
    double? brokerageBalance,
    double? savingsBalance,
    String? philosophyText,
  }) =>
      UserSettings(
        monthlyNetIncome: monthlyNetIncome ?? this.monthlyNetIncome,
        targetSurplusLow: targetSurplusLow ?? this.targetSurplusLow,
        targetSurplusHigh: targetSurplusHigh ?? this.targetSurplusHigh,
        birthday: clearBirthday ? null : (birthday ?? this.birthday),
        rothIraAnnualTarget: rothIraAnnualTarget ?? this.rothIraAnnualTarget,
        rothIraContributed: rothIraContributed ?? this.rothIraContributed,
        brokerageBalance: brokerageBalance ?? this.brokerageBalance,
        savingsBalance: savingsBalance ?? this.savingsBalance,
        philosophyText: philosophyText ?? this.philosophyText,
      );
}

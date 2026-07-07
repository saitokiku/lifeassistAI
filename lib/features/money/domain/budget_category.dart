/// Budget category domain model and flag-rule types.
library;

export '../../../core/storage/app_database.dart' show BudgetCategory;

/// How a category is policed. Stored as text on the row so rules are
/// user-editable data, not code.
enum BudgetFlagType {
  none,
  warnOverTarget,
  warnOverZero,
  warnOverZeroUnlessIntentional,
  criticalOverZero;

  static BudgetFlagType parse(String raw) => switch (raw) {
        'none' => BudgetFlagType.none,
        'warnOverZero' => BudgetFlagType.warnOverZero,
        'warnOverZeroUnlessIntentional' =>
          BudgetFlagType.warnOverZeroUnlessIntentional,
        'criticalOverZero' => BudgetFlagType.criticalOverZero,
        _ => BudgetFlagType.warnOverTarget,
      };

  String get storageKey => name;

  String get label => switch (this) {
        BudgetFlagType.none => 'No flag',
        BudgetFlagType.warnOverTarget => 'Warn over target',
        BudgetFlagType.warnOverZero => 'Warn over \$0',
        BudgetFlagType.warnOverZeroUnlessIntentional =>
          'Warn over \$0 unless intentional',
        BudgetFlagType.criticalOverZero => 'Critical over \$0',
      };
}

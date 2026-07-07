/// Freedom target domain model.
library;

export '../../../core/storage/app_database.dart' show FreedomTarget;

import '../../../core/storage/app_database.dart';

extension FreedomTargetX on FreedomTarget {
  double get passiveIncomeProgress => targetMonthlyPassiveIncome <= 0
      ? 0
      : (currentMonthlyPassiveIncome / targetMonthlyPassiveIncome)
          .clamp(0.0, 1.0);

  double get netWorthProgress => targetLiquidNetWorth <= 0
      ? 0
      : (currentLiquidNetWorth / targetLiquidNetWorth).clamp(0.0, 1.0);
}

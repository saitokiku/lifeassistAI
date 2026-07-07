/// Goal domain model.
library;

export '../../../core/storage/app_database.dart' show Goal;

import '../../../core/storage/app_database.dart';

extension GoalX on Goal {
  double get progress => targetValue <= 0
      ? 0
      : (currentValue / targetValue).clamp(0.0, 1.0);
}

/// Growth metric domain model. The drift-generated data class is the single
/// source of truth; this file re-exports it and adds domain helpers.
library;

export '../../../core/storage/app_database.dart' show GrowthMetric;

import '../../../core/storage/app_database.dart';

extension GrowthMetricX on GrowthMetric {
  /// Progress toward the weekly target, clamped 0..1.
  double get weeklyProgress =>
      weeklyTarget <= 0 ? 0 : (currentValue / weeklyTarget).clamp(0.0, 1.0);
}

import 'package:flutter/material.dart';

import '../../domain/time_category.dart';

/// UI-only glyphs for time category kinds. Presentation concern — the
/// domain enum stays icon-free.
extension TimeCategoryKindIcon on TimeCategoryKind {
  IconData get icon => switch (this) {
        TimeCategoryKind.sleep => Icons.bedtime_outlined,
        TimeCategoryKind.job => Icons.work_outline,
        TimeCategoryKind.kaizen => Icons.trending_up,
        TimeCategoryKind.admin => Icons.checklist,
        TimeCategoryKind.decompress => Icons.weekend_outlined,
        TimeCategoryKind.meals => Icons.restaurant_outlined,
        TimeCategoryKind.exercise => Icons.fitness_center,
        TimeCategoryKind.volunteering => Icons.volunteer_activism_outlined,
        TimeCategoryKind.toastmasters => Icons.record_voice_over_outlined,
        TimeCategoryKind.meditation => Icons.self_improvement,
        TimeCategoryKind.other => Icons.category_outlined,
      };
}

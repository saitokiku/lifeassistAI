import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// How a daily action went. Stored values keep their pre-v2 names
/// (`kill` / `confirm` / `iterate`) so existing rows stay valid.
enum ActionVerdict {
  didntWork('kill'),
  worked('confirm'),
  adjust('iterate');

  const ActionVerdict(this.storageValue);

  /// The string persisted in the database.
  final String storageValue;

  static ActionVerdict parse(String raw) => switch (raw) {
        'kill' => ActionVerdict.didntWork,
        'confirm' => ActionVerdict.worked,
        _ => ActionVerdict.adjust,
      };

  String get label => switch (this) {
        ActionVerdict.didntWork => "Didn't work",
        ActionVerdict.worked => 'Worked',
        ActionVerdict.adjust => 'Adjust',
      };

  Color get color => switch (this) {
        ActionVerdict.didntWork => AppColors.critical,
        ActionVerdict.worked => AppColors.aligned,
        ActionVerdict.adjust => AppColors.watch,
      };
}

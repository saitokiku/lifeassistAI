import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One test. One verdict.
enum ExperimentVerdict {
  kill,
  confirm,
  iterate;

  static ExperimentVerdict parse(String raw) => switch (raw) {
        'kill' => ExperimentVerdict.kill,
        'confirm' => ExperimentVerdict.confirm,
        _ => ExperimentVerdict.iterate,
      };

  String get label => switch (this) {
        ExperimentVerdict.kill => 'Kill',
        ExperimentVerdict.confirm => 'Confirm',
        ExperimentVerdict.iterate => 'Iterate',
      };

  Color get color => switch (this) {
        ExperimentVerdict.kill => AppColors.critical,
        ExperimentVerdict.confirm => AppColors.aligned,
        ExperimentVerdict.iterate => AppColors.watch,
      };
}

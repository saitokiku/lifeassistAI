import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// What happened to a parked idea after cooling.
enum IdeaDecision {
  undecided,
  ignore,
  later,
  integrate;

  static IdeaDecision parse(String raw) => IdeaDecision.values
      .firstWhere((d) => d.name == raw, orElse: () => IdeaDecision.undecided);

  String get label => switch (this) {
        IdeaDecision.undecided => 'Undecided',
        IdeaDecision.ignore => 'Ignore',
        IdeaDecision.later => 'Later',
        IdeaDecision.integrate => 'Integrate',
      };

  Color get color => switch (this) {
        IdeaDecision.undecided => AppColors.neutral,
        IdeaDecision.ignore => AppColors.critical,
        IdeaDecision.later => AppColors.watch,
        IdeaDecision.integrate => AppColors.aligned,
      };
}

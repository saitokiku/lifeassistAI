import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../application/time_state.dart';

/// Available time today and remaining weekly budget.
class AvailableTimeCard extends StatelessWidget {
  const AvailableTimeCard({super.key, required this.state});

  final TimeState state;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      title: 'Available time today',
      bigValue: Formatters.hours(state.availableHoursToday),
      supportText:
          '${Formatters.hours(state.hoursLoggedToday)} logged today · ${Formatters.hours(state.remainingWeekHours)} of weekly targets remaining · ${AppCopy.availableTimeBudget}',
    );
  }
}

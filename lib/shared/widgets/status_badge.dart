import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Small colored pill: ALIGNED / WATCH / DRIFTING / CRITICAL etc.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.level});

  final String label;
  final StatusLevel level;

  @override
  Widget build(BuildContext context) {
    final color = level.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

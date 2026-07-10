import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/weekdays.dart';
import '../haptics.dart';

/// Seven tappable day dots (Monday-first) editing a weekday bitmask.
/// Never lets the last selected day be turned off — an empty schedule is
/// a disabled reminder, not a valid schedule.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    super.key,
    required this.mask,
    required this.onChanged,
  });

  final int mask;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.brightness == Brightness.dark
        ? AppColors.primaryBright
        : AppColors.primaryDim;

    return Row(
      children: [
        for (var day = DateTime.monday; day <= DateTime.sunday; day++) ...[
          if (day != DateTime.monday) const SizedBox(width: 6),
          Expanded(
            child: _DayDot(
              label: WeekdayMask.shortLabels[day - DateTime.monday],
              name: WeekdayMask.dayNames[day - DateTime.monday],
              selected: WeekdayMask.has(mask, day),
              accent: accent,
              onTap: () {
                final next = WeekdayMask.toggle(mask, day);
                if (next & WeekdayMask.all == 0) return; // keep one day
                Haptics.select();
                onChanged(next);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.name,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String name;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      label: name,
      toggled: selected,
      button: true,
      child: Material(
        color: selected
            ? Color.alphaBlend(scheme.primaryTint, scheme.elevated)
            : scheme.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? scheme.primaryTintBorder : scheme.outlineFaint,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? accent : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

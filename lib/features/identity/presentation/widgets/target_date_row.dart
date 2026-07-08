import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';

/// Optional-date form row: the whole row opens the picker, the × clears it.
class TargetDateRow extends StatelessWidget {
  const TargetDateRow({
    super.key,
    required this.date,
    required this.onChanged,
    this.emptyLabel = 'Add a target date',
  });

  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  final String emptyLabel;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDate = date != null;

    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xs,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                hasDate ? Formatters.fullDate(date!) : emptyLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasDate ? null : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (hasDate)
              IconButton(
                tooltip: 'Clear date',
                visualDensity: VisualDensity.compact,
                onPressed: () => onChanged(null),
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

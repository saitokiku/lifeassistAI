import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/monthly_money_snapshot.dart';

/// The hero: projected end-of-month surplus, its status, and the pace
/// that produces it. One number the whole screen answers to.
class SurplusCard extends StatelessWidget {
  const SurplusCard({super.key, required this.snapshot, this.onEditIncome});

  final MonthlyMoneySnapshot snapshot;
  final VoidCallback? onEditIncome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ScoreUtils.surplusStatus(
      projectedSurplus: snapshot.projectedSurplus,
      targetSurplusLow: snapshot.targetSurplusLow,
    );
    final label = ScoreUtils.surplusLabel(
      projectedSurplus: snapshot.projectedSurplus,
      targetSurplusLow: snapshot.targetSurplusLow,
      targetSurplusHigh: snapshot.targetSurplusHigh,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SURPLUS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.textTertiary,
                  ),
                ),
              ),
              if (onEditIncome != null)
                TextButton(
                  onPressed: onEditIncome,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpace.md),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                Formatters.moneySigned(snapshot.projectedSurplus),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(width: AppSpace.md),
              StatusBadge(label: label, level: status),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'projected · target ${Formatters.money(snapshot.targetSurplusLow)}–${Formatters.money(snapshot.targetSurplusHigh)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          _PaceBar(
            spent: snapshot.spendSoFar,
            projected: snapshot.projectedSpend,
            income: snapshot.monthlyNetIncome,
            color: status.color,
          ),
          const SizedBox(height: AppSpace.lg),
          _row(theme, 'Net monthly income',
              Formatters.money(snapshot.monthlyNetIncome)),
          _row(theme, 'Spend month-to-date',
              Formatters.money(snapshot.spendSoFar)),
          _row(theme, 'Projected spend',
              Formatters.money(snapshot.projectedSpend),
              last: true),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value,
      {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: theme.textTheme.numberBody),
        ],
      ),
    );
  }
}

/// Thin pace bar: solid fill = spend so far, soft fill = projected spend,
/// track = monthly net income. When the projection outruns income the whole
/// bar fills — and the status color already says so.
class _PaceBar extends StatelessWidget {
  const _PaceBar({
    required this.spent,
    required this.projected,
    required this.income,
    required this.color,
  });

  final double spent;
  final double projected;
  final double income;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var denom = math.max(income, math.max(projected, spent));
    if (denom <= 0) denom = 1;
    final spentF = (spent / denom).clamp(0.0, 1.0);
    final projectedF = (projected / denom).clamp(0.0, 1.0);

    return Semantics(
      label:
          'Spent ${Formatters.money(spent)} of ${Formatters.money(income)} income, projecting ${Formatters.money(projected)}.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              width: w,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: theme.colorScheme.outlineVariant),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: w * projectedF,
                    child: ColoredBox(color: color.withValues(alpha: 0.3)),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: w * spentF,
                    child: ColoredBox(color: color),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

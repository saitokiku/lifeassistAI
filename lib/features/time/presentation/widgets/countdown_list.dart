import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../application/time_controller.dart';
import '../../domain/countdown.dart';
import 'birthday_sheet.dart';
import 'countdown_editor.dart';

/// Countdown tiles, two per row. Tap to edit; the age-28 tile asks for a
/// birthday inline until one is set.
class CountdownList extends StatelessWidget {
  const CountdownList({super.key, required this.countdowns});

  final List<ResolvedCountdown> countdowns;

  @override
  Widget build(BuildContext context) {
    if (countdowns.isEmpty) {
      return EmptyState(
        icon: Icons.hourglass_bottom,
        title: 'Nothing on the clock',
        message: 'Deadlines only work when you can see them coming. Add one.',
        actionLabel: 'New countdown',
        onAction: () => CountdownEditor.show(context),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpace.cardGap;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final rc in countdowns)
              SizedBox(width: tileWidth, child: _CountdownTile(rc: rc)),
          ],
        );
      },
    );
  }
}

class _CountdownTile extends StatelessWidget {
  const _CountdownTile({required this.rc});

  final ResolvedCountdown rc;

  /// The main goal's deadline, injected at read time — edited on Focus,
  /// not through the countdown editor.
  bool get _isGoalTarget =>
      rc.countdown.dynamicKey == goalTargetCountdownKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.tilePadding),
      onTap: _isGoalTarget
          ? () => context.go('/focus')
          : rc.needsBirthday
              ? () => BirthdaySheet.show(context)
              : () => CountdownEditor.show(context, countdown: rc.countdown),
      onLongPress: rc.needsBirthday
          ? () => CountdownEditor.show(context, countdown: rc.countdown)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_isGoalTarget) ...[
                Icon(
                  Icons.outlined_flag,
                  size: 14,
                  color: theme.colorScheme.brandLabel,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  rc.countdown.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          // scaleDown keeps huge accessibility text sizes from overflowing
          // the fixed-width tile.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _value(theme),
          ),
          const SizedBox(height: 2),
          _caption(theme),
        ],
      ),
    );
  }

  Widget _value(ThemeData theme) {
    if (rc.needsBirthday) {
      return Text(
        'Set birthday',
        style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary),
      );
    }
    final daysLeft = rc.daysLeft;
    if (rc.targetDate == null || daysLeft == null) {
      return Text(
        '—',
        style: theme.textTheme.numberMedium.copyWith(color: AppColors.neutral),
      );
    }
    if (daysLeft < 0) {
      return Text(
        'Passed',
        style: theme.textTheme.numberMedium.copyWith(color: AppColors.neutral),
      );
    }
    if (daysLeft == 0) {
      return Text(
        'Today',
        style: theme.textTheme.numberMedium.copyWith(color: AppColors.watch),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$daysLeft',
          style: theme.textTheme.numberMedium.copyWith(
            color: daysLeft < 30 ? AppColors.watch : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          daysLeft == 1 ? 'day' : 'days',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _caption(ThemeData theme) {
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.textTertiary,
    );
    if (_isGoalTarget && rc.targetDate != null) {
      return Text('Your goal · ${Formatters.shortDate(rc.targetDate!)}',
          maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    if (rc.needsBirthday) {
      return Text('Needed to start this clock.',
          maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    final target = rc.targetDate;
    final daysLeft = rc.daysLeft;
    if (target == null || daysLeft == null) {
      return Text('No date set.',
          maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    if (daysLeft < 0) {
      final ago = -daysLeft;
      return Text(
        ago == 1 ? 'Yesterday' : '$ago days ago',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return Text(
      Formatters.fullDate(target),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

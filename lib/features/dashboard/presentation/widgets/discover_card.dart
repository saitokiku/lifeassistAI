import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';

/// One-time launch tour: three quiet rows pointing at the things a new
/// (or updated) install would otherwise take weeks to find — the
/// Zettelkasten, Apple Health auto-habits, and the widgets. Dismissed
/// once, gone forever; rows navigate straight to the feature.
class DiscoverCard extends ConsumerStatefulWidget {
  const DiscoverCard({super.key});

  @override
  ConsumerState<DiscoverCard> createState() => _DiscoverCardState();
}

class _DiscoverCardState extends ConsumerState<DiscoverCard> {
  bool _dismissed = false;

  void _dismiss() {
    setState(() => _dismissed = true);
    ref.read(preferencesProvider).setLaunchDiscoveryDismissed();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || ref.read(preferencesProvider).launchDiscoveryDismissed) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sectionGap),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Worth finding',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.brandLabel,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  visualDensity: VisualDensity.compact,
                  onPressed: _dismiss,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: scheme.textTertiary,
                  ),
                ),
              ],
            ),
            _DiscoverRow(
              icon: Icons.hub_outlined,
              title: 'Notes that link like a mind map',
              caption: 'Write [[connections]]; watch the graph grow.',
              onTap: () => context.push('/notes'),
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: AppSpace.sm),
              _DiscoverRow(
                icon: Icons.favorite_outline,
                title: 'Habits that check themselves',
                caption: 'Connect Apple Health in Settings; map steps, '
                    'sleep, workouts.',
                onTap: () => context.push('/settings'),
              ),
              const SizedBox(height: AppSpace.sm),
              _DiscoverRow(
                icon: Icons.widgets_outlined,
                title: 'Widgets on your Home Screen',
                caption: 'Day score, up next, and one-tap habit checks — '
                    'long-press your Home Screen to add.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DiscoverRow extends StatelessWidget {
  const _DiscoverRow({
    required this.icon,
    required this.title,
    required this.caption,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(
                    caption,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: scheme.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

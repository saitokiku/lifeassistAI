import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_tokens.dart';
import '../features/search/presentation/search_sheet.dart';
import 'app_icons.dart';
import 'pressable.dart';

/// The canonical screen header for tab roots: title, optional subtitle,
/// and the two global affordances — search and You — on every screen
/// (You left the tab bar to make room for the centered capture button).
/// Ends the per-screen header drift.
class TabPageHeader extends StatelessWidget {
  const TabPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showGlobalActions = true,
  });

  final String title;
  final String? subtitle;

  /// Screen-specific actions, rendered before the global pair.
  final List<Widget> actions;

  final bool showGlobalActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: theme.textTheme.headlineSmall),
            ),
            ...actions,
            if (showGlobalActions) ...[
              HeaderGlyphButton(
                icon: AppIcons.search,
                tooltip: 'Search',
                onTap: () => SearchSheet.show(context),
              ),
              const SizedBox(width: 2),
              HeaderGlyphButton(
                icon: AppIcons.you,
                tooltip: 'You',
                onTap: () => context.go('/more'),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// A quiet 36px glyph button for headers — hairline circle, no ink.
class HeaderGlyphButton extends StatelessWidget {
  const HeaderGlyphButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        haptic: PressHaptic.select,
        semanticLabel: tooltip,
        pressedScale: 0.9,
        dense: true,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outline),
          ),
          child: Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

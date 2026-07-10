import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../haptics.dart';
import 'adaptive_navigation.dart';
import 'responsive_scaffold.dart';

/// Shell around every top-level screen: rail on wide, bottom bar on compact.
///
/// Compact shows five tabs (Today · Focus · Money · Time · You) backed by
/// an indexed stack, so each tab keeps its scroll position and state.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      body: shell,
      railBuilder: (context) => _buildRail(context),
      bottomBarBuilder: (context) => _buildBottomBar(context),
    );
  }

  Widget _buildRail(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = AppDestinations.railIndexForLocation(location);

    return SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).vertical,
          ),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (index) {
                Haptics.select();
                context.go(AppDestinations.rail[index].route);
              },
              destinations: [
                for (final d in AppDestinations.rail)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) {
        Haptics.select();
        // Re-tapping the active tab pops that branch back to its root.
        shell.goBranch(index, initialLocation: index == shell.currentIndex);
      },
      destinations: [
        for (final d in AppDestinations.compact)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          ),
      ],
    );
  }
}

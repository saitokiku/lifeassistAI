import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'adaptive_navigation.dart';
import 'responsive_scaffold.dart';

/// Shell around every top-level screen: rail on wide, bottom bar on compact.
/// Compact shows Dashboard/Kaizen/Money/Time plus a More tab.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = AppDestinations.indexForLocation(location);

    return ResponsiveScaffold(
      body: child,
      railBuilder: (context) => _buildRail(context, selectedIndex),
      bottomBarBuilder: (context) => _buildBottomBar(context, location),
    );
  }

  Widget _buildRail(BuildContext context, int selectedIndex) {
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
              onDestinationSelected: (index) =>
                  context.go(AppDestinations.all[index].route),
              destinations: [
                for (final d in AppDestinations.all)
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

  Widget _buildBottomBar(BuildContext context, String location) {
    final compact =
        AppDestinations.all.take(AppDestinations.compactCount).toList();
    final onMoreScreen =
        AppDestinations.moreRoutes.any(location.startsWith);
    final compactIndex = compact.indexWhere((d) => location.startsWith(d.route));
    final selectedIndex =
        onMoreScreen ? compact.length : (compactIndex < 0 ? 0 : compactIndex);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index == compact.length) {
          context.go('/more');
        } else {
          context.go(compact[index].route);
        }
      },
      destinations: [
        for (final d in compact)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          ),
        const NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view),
          label: 'More',
        ),
      ],
    );
  }
}

/// The "More" tab on compact layouts: links to the remaining screens.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final more = AppDestinations.all.skip(AppDestinations.compactCount);
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          for (final d in more)
            ListTile(
              leading: Icon(d.icon),
              title: Text(d.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(d.route),
            ),
        ],
      ),
    );
  }
}

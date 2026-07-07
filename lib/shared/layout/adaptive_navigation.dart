import 'package:flutter/material.dart';

/// One navigation destination = one top-level screen.
class AppDestination {
  const AppDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// All nine screens. Wide layouts show everything in a rail; compact layouts
/// show the first four plus a "More" tab that fans out to the rest.
class AppDestinations {
  AppDestinations._();

  static const all = <AppDestination>[
    AppDestination(
      route: '/dashboard',
      label: 'Dashboard',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
    ),
    AppDestination(
      route: '/kaizen',
      label: 'Kaizen',
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up,
    ),
    AppDestination(
      route: '/money',
      label: 'Money',
      icon: Icons.account_balance_outlined,
      selectedIcon: Icons.account_balance,
    ),
    AppDestination(
      route: '/time',
      label: 'Time',
      icon: Icons.hourglass_empty_outlined,
      selectedIcon: Icons.hourglass_full,
    ),
    AppDestination(
      route: '/habits',
      label: 'Habits',
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
    ),
    AppDestination(
      route: '/ideas',
      label: 'Ideas',
      icon: Icons.lightbulb_outline,
      selectedIcon: Icons.lightbulb,
    ),
    AppDestination(
      route: '/identity',
      label: 'Identity',
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
    ),
    AppDestination(
      route: '/reminders',
      label: 'Reminders',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
    ),
    AppDestination(
      route: '/settings',
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  /// Compact bottom bar: Dashboard, Kaizen, Money, Time, More.
  static const compactCount = 4;

  static const moreRoutes = ['/habits', '/ideas', '/identity', '/reminders', '/settings', '/more'];

  static int indexForLocation(String location) {
    for (var i = 0; i < all.length; i++) {
      if (location.startsWith(all[i].route)) return i;
    }
    return 0;
  }
}

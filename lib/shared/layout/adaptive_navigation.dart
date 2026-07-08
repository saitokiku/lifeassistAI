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

/// Navigation structure.
///
/// Compact (phones): five tabs — Today, Kaizen, Money, Time, You.
/// The You tab is a hub for Identity, Habits, Ideas, Reminders, Settings.
/// Wide (rail): every screen, flat.
class AppDestinations {
  AppDestinations._();

  /// Bottom bar tabs, in branch order (must match the router's branches).
  static const compact = <AppDestination>[
    AppDestination(
      route: '/dashboard',
      label: 'Today',
      icon: Icons.wb_sunny_outlined,
      selectedIcon: Icons.wb_sunny,
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
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    AppDestination(
      route: '/time',
      label: 'Time',
      icon: Icons.schedule_outlined,
      selectedIcon: Icons.schedule,
    ),
    AppDestination(
      route: '/more',
      label: 'You',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  /// Wide-layout rail: all screens.
  static const rail = <AppDestination>[
    AppDestination(
      route: '/dashboard',
      label: 'Today',
      icon: Icons.wb_sunny_outlined,
      selectedIcon: Icons.wb_sunny,
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
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    AppDestination(
      route: '/time',
      label: 'Time',
      icon: Icons.schedule_outlined,
      selectedIcon: Icons.schedule,
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

  /// Rail selection for the current location; null when nothing matches
  /// (e.g. the /more hub, which only exists as a compact tab).
  static int? railIndexForLocation(String location) {
    for (var i = 0; i < rail.length; i++) {
      if (location.startsWith(rail[i].route)) return i;
    }
    return null;
  }
}

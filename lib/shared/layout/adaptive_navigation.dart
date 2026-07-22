import 'package:flutter/widgets.dart';

import '../../ui/app_icons.dart';

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
/// Compact (phones): five tabs — Today, Focus, Money, Time, You.
/// Focus is the user's main goal; You is the hub for principles, habits,
/// ideas, reminders, and settings.
/// Wide (rail): every screen, flat.
class AppDestinations {
  AppDestinations._();

  /// Bottom bar tabs, in branch order (must match the router's branches).
  static const compact = <AppDestination>[
    AppDestination(
      route: '/today',
      label: 'Today',
      icon: AppIcons.today,
      selectedIcon: AppIcons.today,
    ),
    AppDestination(
      route: '/focus',
      label: 'Focus',
      icon: AppIcons.focus,
      selectedIcon: AppIcons.focus,
    ),
    AppDestination(
      route: '/money',
      label: 'Money',
      icon: AppIcons.money,
      selectedIcon: AppIcons.money,
    ),
    AppDestination(
      route: '/time',
      label: 'Time',
      icon: AppIcons.time,
      selectedIcon: AppIcons.time,
    ),
    AppDestination(
      route: '/more',
      label: 'You',
      icon: AppIcons.you,
      selectedIcon: AppIcons.you,
    ),
  ];

  /// Wide-layout rail: all screens.
  static const rail = <AppDestination>[
    AppDestination(
      route: '/today',
      label: 'Today',
      icon: AppIcons.today,
      selectedIcon: AppIcons.today,
    ),
    AppDestination(
      route: '/focus',
      label: 'Focus',
      icon: AppIcons.focus,
      selectedIcon: AppIcons.focus,
    ),
    AppDestination(
      route: '/money',
      label: 'Money',
      icon: AppIcons.money,
      selectedIcon: AppIcons.money,
    ),
    AppDestination(
      route: '/time',
      label: 'Time',
      icon: AppIcons.time,
      selectedIcon: AppIcons.time,
    ),
    AppDestination(
      route: '/habits',
      label: 'Habits',
      icon: AppIcons.habits,
      selectedIcon: AppIcons.habits,
    ),
    AppDestination(
      route: '/ideas',
      label: 'Ideas',
      icon: AppIcons.ideas,
      selectedIcon: AppIcons.ideas,
    ),
    AppDestination(
      route: '/reminders',
      label: 'Reminders',
      icon: AppIcons.reminders,
      selectedIcon: AppIcons.reminders,
    ),
    AppDestination(
      route: '/more',
      label: 'You',
      icon: AppIcons.you,
      selectedIcon: AppIcons.you,
    ),
    AppDestination(
      route: '/settings',
      label: 'Settings',
      icon: AppIcons.settings,
      selectedIcon: AppIcons.settings,
    ),
  ];

  /// Rail selection for the current location; null when nothing matches.
  static int? railIndexForLocation(String location) {
    for (var i = 0; i < rail.length; i++) {
      if (location.startsWith(rail[i].route)) return i;
    }
    return null;
  }
}

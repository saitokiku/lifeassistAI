import 'package:flutter/material.dart';

import '../domain/user_settings.dart';

/// App-level settings view state: DB-backed settings + device prefs.
class SettingsState {
  const SettingsState({
    required this.settings,
    required this.themeMode,
    required this.notificationsEnabled,
  });

  final UserSettings settings;
  final ThemeMode themeMode;
  final bool notificationsEnabled;
}

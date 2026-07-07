import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_keys.dart';

/// Thin wrapper over SharedPreferences for small app flags only.
/// Core user data lives in the database (see SettingsRepository).
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static Future<PreferencesService> create() async =>
      PreferencesService(await SharedPreferences.getInstance());

  bool get onboardingComplete =>
      _prefs.getBool(SettingsKeys.prefOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(SettingsKeys.prefOnboardingComplete, value);

  ThemeMode get themeMode {
    final raw = _prefs.getString(SettingsKeys.prefThemeMode);
    return switch (raw) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark, // dark mode first
    };
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(SettingsKeys.prefThemeMode, mode.name);

  bool get notificationsEnabled =>
      _prefs.getBool(SettingsKeys.prefNotificationsEnabled) ?? false;

  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(SettingsKeys.prefNotificationsEnabled, value);
}

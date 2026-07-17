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

  bool get launchDiscoveryDismissed =>
      _prefs.getBool(SettingsKeys.prefLaunchDiscoveryDismissed) ?? false;

  Future<void> setLaunchDiscoveryDismissed() =>
      _prefs.setBool(SettingsKeys.prefLaunchDiscoveryDismissed, true);

  /// Seeds/legacy migration are skipped while this matches the app's
  /// current revision. Cleared by reset and import so both re-run.
  int get dataRevision => _prefs.getInt(SettingsKeys.prefDataRevision) ?? 0;

  Future<void> setDataRevision(int value) =>
      _prefs.setInt(SettingsKeys.prefDataRevision, value);

  Future<void> clearDataRevision() =>
      _prefs.remove(SettingsKeys.prefDataRevision);

  bool get appLockEnabled =>
      _prefs.getBool(SettingsKeys.prefAppLockEnabled) ?? false;

  Future<void> setAppLockEnabled(bool value) =>
      _prefs.setBool(SettingsKeys.prefAppLockEnabled, value);

  DateTime? get lastAutoBackupAt {
    final raw = _prefs.getString(SettingsKeys.prefLastAutoBackupAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastAutoBackupAt(DateTime value) => _prefs.setString(
      SettingsKeys.prefLastAutoBackupAt, value.toIso8601String());

  /// Live time-block timer (survives restarts). Null when none running.
  ({String budgetId, DateTime startedAt})? get runningTimer {
    final id = _prefs.getString(SettingsKeys.prefTimerBudgetId);
    final raw = _prefs.getString(SettingsKeys.prefTimerStartedAt);
    final startedAt = raw == null ? null : DateTime.tryParse(raw);
    if (id == null || startedAt == null) return null;
    return (budgetId: id, startedAt: startedAt);
  }

  Future<void> setRunningTimer(String budgetId, DateTime startedAt) async {
    await _prefs.setString(SettingsKeys.prefTimerBudgetId, budgetId);
    await _prefs.setString(
        SettingsKeys.prefTimerStartedAt, startedAt.toIso8601String());
  }

  Future<void> clearRunningTimer() async {
    await _prefs.remove(SettingsKeys.prefTimerBudgetId);
    await _prefs.remove(SettingsKeys.prefTimerStartedAt);
  }
}

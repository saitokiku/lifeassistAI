import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/settings_keys.dart';
import '../data/settings_repository.dart';
import '../domain/user_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

/// DB-backed user settings (name, income, targets, birthday, philosophy...).
final settingsProvider = StreamProvider<UserSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watchSettings(),
);

/// Theme mode lives in SharedPreferences; a StateProvider mirrors it so the
/// MaterialApp rebuilds immediately on change.
final themeModeProvider = StateProvider<ThemeMode>(
  (ref) => ref.watch(preferencesProvider).themeMode,
);

/// App-level notifications toggle (also SharedPreferences).
final notificationsEnabledProvider = StateProvider<bool>(
  (ref) => ref.watch(preferencesProvider).notificationsEnabled,
);

class SettingsController {
  SettingsController(this._ref);

  final Ref _ref;

  SettingsRepository get _repo => _ref.read(settingsRepositoryProvider);

  Future<void> setDisplayName(String name) =>
      _repo.setValue(SettingsKeys.displayName, name.trim());

  Future<void> setMonthlyNetIncome(double value) =>
      _repo.setNumber(SettingsKeys.monthlyNetIncome, value);

  Future<void> setTargetSurplus(
      {required double low, required double high}) async {
    await _repo.setNumber(SettingsKeys.targetSurplusLow, low);
    await _repo.setNumber(SettingsKeys.targetSurplusHigh, high);
  }

  Future<void> setBirthday(DateTime? birthday) => _repo.setBirthday(birthday);

  Future<void> setPhilosophyText(String text) =>
      _repo.setValue(SettingsKeys.philosophyText, text);

  Future<void> setDashboardAreas(Set<DashboardArea> areas) =>
      _repo.setValue(SettingsKeys.dashboardAreas, DashboardArea.encode(areas));

  Future<void> setThemeMode(ThemeMode mode) async {
    await _ref.read(preferencesProvider).setThemeMode(mode);
    _ref.read(themeModeProvider.notifier).state = mode;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _ref.read(preferencesProvider).setNotificationsEnabled(enabled);
    _ref.read(notificationsEnabledProvider.notifier).state = enabled;
  }
}

final settingsControllerProvider =
    Provider<SettingsController>((ref) => SettingsController(ref));

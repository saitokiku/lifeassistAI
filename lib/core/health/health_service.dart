import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where HealthKit stands on this install. Read grants are invisible by
/// HealthKit design, so "ready" means the APIs are callable — absent data
/// and denied permission look identical and the UI must never claim to
/// know the difference.
enum HealthAvailability {
  /// This build has no HealthKit capability (LAHealthKitEnabled is off).
  disabledInBuild,

  /// Device has no health store (some iPads) — or not an iOS device.
  notSupported,

  /// Callable. Ask for permission, then query.
  ready;

  static HealthAvailability parse(String? raw) => switch (raw) {
        'ready' => HealthAvailability.ready,
        'notSupported' => HealthAvailability.notSupported,
        _ => HealthAvailability.disabledInBuild,
      };
}

/// One day of health numbers. Any field can be null: no data recorded,
/// or read permission withheld — indistinguishable, and worded as such.
class HealthDailySummary {
  const HealthDailySummary({
    this.steps,
    this.sleepHours,
    this.mindfulMinutes,
    this.workoutMinutes,
  });

  final int? steps;
  final double? sleepHours;
  final double? mindfulMinutes;
  final double? workoutMinutes;

  static HealthDailySummary fromMap(Map<Object?, Object?> map) =>
      HealthDailySummary(
        steps: (map['steps'] as num?)?.toInt(),
        sleepHours: (map['sleepHours'] as num?)?.toDouble(),
        mindfulMinutes: (map['mindfulMinutes'] as num?)?.toDouble(),
        workoutMinutes: (map['workoutMinutes'] as num?)?.toDouble(),
      );
}

/// Dart face of the `lifeassist/health` channel (HealthBridge.swift).
/// Phase 5 scaffold: the auto-habit mapping UI arrives with the phase;
/// this service is complete and tested so that work is purely Dart.
class HealthService {
  HealthService({@visibleForTesting MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('lifeassist/health');

  final MethodChannel _channel;

  bool get _platformSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<HealthAvailability> availability() async {
    if (!_platformSupported) return HealthAvailability.notSupported;
    try {
      return HealthAvailability.parse(
          await _channel.invokeMethod<String>('availability'));
    } catch (_) {
      return HealthAvailability.notSupported;
    }
  }

  /// Shows the HealthKit permission sheet. Returns whether the sheet
  /// completed — NOT whether access was granted (HealthKit hides that).
  Future<bool> requestPermission() async {
    if (!_platformSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<HealthDailySummary?> dailySummary(DateTime day) async {
    if (!_platformSupported) return null;
    final dateIso = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
          'dailySummary', {'dateIso': dateIso});
      if (raw == null) return null;
      return HealthDailySummary.fromMap(raw);
    } catch (_) {
      return null;
    }
  }
}

final healthServiceProvider = Provider<HealthService>(
  (ref) => HealthService(),
);

final healthAvailabilityProvider = FutureProvider<HealthAvailability>(
  (ref) => ref.watch(healthServiceProvider).availability(),
);

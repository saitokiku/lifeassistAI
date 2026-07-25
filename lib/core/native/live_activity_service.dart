import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dart face of `lifeassist/activity` (ActivityBridge.swift): the
/// focus-timer Live Activity on the lock screen / Dynamic Island.
///
/// Strictly a mirror of real timer state — started with the in-app
/// timer, ended with it. Every call is best-effort: no Live Activities
/// (old iOS, user setting, Android, web) means the in-app timer simply
/// runs without one.
class LiveActivityService {
  LiveActivityService({@visibleForTesting MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('lifeassist/activity');

  final MethodChannel _channel;

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> startFocusTimer({
    required String label,
    required DateTime startedAt,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('startFocusTimer', {
        'label': label,
        'startedAtIso': startedAt.toUtc().toIso8601String(),
      });
    } catch (_) {
      // No activity — the in-app timer is still the source of truth.
    }
  }

  Future<void> stopFocusTimer() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('stopFocusTimer');
    } catch (_) {}
  }

  /// Ends any Live Activity left over from a previous process when no
  /// timer is actually running. iOS keeps activities alive for hours
  /// after the app is killed, so without this a force-quit (or "Reset
  /// all data") left a lock-screen timer counting with no way to
  /// dismiss it from the app.
  Future<void> reconcile({required bool timerRunning}) async {
    if (!_supported || timerRunning) return;
    await stopFocusTimer();
  }
}

final liveActivityServiceProvider = Provider<LiveActivityService>(
  (ref) => LiveActivityService(),
);

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/health/health_service.dart';

/// Scaffold contract: availability states map, summaries parse,
/// and non-iOS platforms never touch the channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('lifeassist/health');

  HealthService serviceAnswering(
    Future<Object?> Function(MethodCall call) handler,
  ) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
    return HealthService(channel: channel);
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('non-iOS platforms report notSupported without touching the channel',
      () async {
    var called = false;
    final service = serviceAnswering((_) async {
      called = true;
      return 'ready';
    });
    expect(await service.availability(), HealthAvailability.notSupported);
    expect(await service.dailySummary(DateTime(2026, 7, 11)), isNull);
    expect(await service.requestPermission(), isFalse);
    expect(called, isFalse);
  });

  test('parse covers every bridge state, unknown degrades to disabled', () {
    expect(HealthAvailability.parse('ready'), HealthAvailability.ready);
    expect(HealthAvailability.parse('notSupported'),
        HealthAvailability.notSupported);
    expect(HealthAvailability.parse('disabledInBuild'),
        HealthAvailability.disabledInBuild);
    expect(HealthAvailability.parse(null), HealthAvailability.disabledInBuild);
  });

  test('summary parses partial data — nulls stay null', () {
    final summary = HealthDailySummary.fromMap(const {
      'steps': 8123,
      'sleepHours': 7.25,
      'mindfulMinutes': null,
      'workoutMinutes': 42.0,
    });
    expect(summary.steps, 8123);
    expect(summary.sleepHours, 7.25);
    expect(summary.mindfulMinutes, isNull);
    expect(summary.workoutMinutes, 42.0);
  });
}

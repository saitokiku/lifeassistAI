import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/ai/ai_service.dart';

/// The AI bridge's Dart face: availability states map correctly, drafts
/// parse defensively, and suggestions can never name a category that
/// isn't real — the same guarantee the Swift side enforces.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('lifeassist/ai');

  AiService serviceAnswering(
    Future<Object?> Function(MethodCall call) handler,
  ) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
    return AiService(channel: channel);
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('availability', () {
    test('non-iOS platforms report unsupported without touching the channel',
        () async {
      // Tests run with defaultTargetPlatform != iOS unless overridden.
      final service = serviceAnswering((_) async => 'available');
      expect(await service.availability(), AiAvailability.unsupportedPlatform);
    });

    test('parse covers every bridge state', () {
      expect(AiAvailability.parse('available'), AiAvailability.available);
      expect(AiAvailability.parse('deviceNotEligible'),
          AiAvailability.deviceNotEligible);
      expect(AiAvailability.parse('appleIntelligenceNotEnabled'),
          AiAvailability.appleIntelligenceNotEnabled);
      expect(
          AiAvailability.parse('modelNotReady'), AiAvailability.modelNotReady);
      expect(AiAvailability.parse('osTooOld'), AiAvailability.osTooOld);
      expect(AiAvailability.parse(null), AiAvailability.unsupportedPlatform);
      expect(AiAvailability.parse('???'), AiAvailability.unsupportedPlatform);
    });
  });

  group('parseCapture', () {
    test('maps drafts and drops malformed entries', () async {
      final service = serviceAnswering((call) async {
        expect(call.method, 'parseCapture');
        final args = call.arguments as Map;
        expect(args['categoryNames'], ['Groceries']);
        return [
          {
            'kind': 'expense',
            'amountCents': 450,
            'text': 'coffee',
            'categoryName': 'Groceries',
          },
          {'kind': 'time', 'hours': 2.0, 'categoryName': 'Deep work'},
          {'amountCents': 999}, // no kind → dropped
        ];
      });
      final drafts = await service.parseCapture(
        'coffee 4.50 and 2h deep work',
        categoryNames: ['Groceries'],
        timeBudgetNames: ['Deep work'],
        habitNames: [],
      );
      expect(drafts, hasLength(2));
      expect(drafts.first.kind, 'expense');
      expect(drafts.first.amountCents, 450);
      expect(drafts.last.hours, 2.0);
    });
  });

  group('categorizeTransactions', () {
    test('keeps only suggestions whose category actually exists', () async {
      final service = serviceAnswering((call) async => [
            {'id': 'a', 'category': 'Groceries'},
            {'id': 'b', 'category': 'Invented'},
          ]);
      final result = await service.categorizeTransactions(
        [(id: 'a', description: 'TRADER JOES'), (id: 'b', description: 'X')],
        categoryNames: ['Groceries'],
      );
      expect(result, {'a': 'Groceries'});
    });

    test('empty input never calls the channel', () async {
      var called = false;
      final service = serviceAnswering((_) async {
        called = true;
        return const [];
      });
      expect(
        await service.categorizeTransactions([], categoryNames: ['G']),
        isEmpty,
      );
      expect(called, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/capture/capture_parser.dart';
import 'package:life_dashboard/core/capture/capture_request.dart';

void main() {
  group('CaptureParser — money', () {
    test('"coffee 4.50" becomes an expense with description', () {
      final items = CaptureParser.parse('coffee 4.50');
      expect(items, hasLength(1));
      final r = items.single.request;
      expect(r.type, CaptureType.expense);
      expect(r.amount, 4.50);
      expect(r.text, 'coffee');
    });

    test(r'"$1200 rent" parses via the dollar sign', () {
      final items = CaptureParser.parse(r'$1200 rent');
      final r = items.single.request;
      expect(r.type, CaptureType.expense);
      expect(r.amount, 1200);
      expect(r.text, 'rent');
    });

    test('"spent 30 on gas" parses via the keyword', () {
      final items = CaptureParser.parse('spent 30 on gas');
      final r = items.single.request;
      expect(r.type, CaptureType.expense);
      expect(r.amount, 30);
    });

    test('European decimal comma "4,50 espresso" parses', () {
      final items = CaptureParser.parse('4,50 espresso');
      final r = items.single.request;
      expect(r.type, CaptureType.expense);
      expect(r.amount, 4.50);
    });

    test('bare integers without money signal stay ideas', () {
      // "call room 12" must NOT become a $12 expense.
      final items = CaptureParser.parse('call room 12');
      expect(items.single.request.type, CaptureType.idea);
    });
  });

  group('CaptureParser — time', () {
    test('"2h deep work" becomes a time block', () {
      final items = CaptureParser.parse('2h deep work');
      final r = items.single.request;
      expect(r.type, CaptureType.time);
      expect(r.hours, 2);
      expect(r.text, 'deep work');
    });

    test('"90 min admin" converts minutes to hours', () {
      final items = CaptureParser.parse('90 min admin');
      final r = items.single.request;
      expect(r.type, CaptureType.time);
      expect(r.hours, closeTo(1.5, 0.001));
    });

    test('"1.5 hours writing" parses decimal hours', () {
      final items = CaptureParser.parse('1.5 hours writing');
      final r = items.single.request;
      expect(r.type, CaptureType.time);
      expect(r.hours, 1.5);
      expect(r.text, 'writing');
    });

    test('absurd hour counts fall through', () {
      final items = CaptureParser.parse('99h nonsense');
      expect(items.single.request.type, isNot(CaptureType.time));
    });
  });

  group('CaptureParser — reminders', () {
    test('"remind me to stretch at 7am" gets text and time', () {
      final items = CaptureParser.parse('remind me to stretch at 7am');
      final r = items.single.request;
      expect(r.type, CaptureType.reminder);
      expect(r.text, 'stretch');
      expect(r.hour, 7);
      expect(r.minute, 0);
    });

    test('pm hours convert to 24h', () {
      final items = CaptureParser.parse('remind me to review at 9:30pm');
      final r = items.single.request;
      expect(r.type, CaptureType.reminder);
      expect(r.hour, 21);
      expect(r.minute, 30);
    });

    test('12am maps to hour 0', () {
      final items = CaptureParser.parse('remind me to sleep at 12am');
      expect(items.single.request.hour, 0);
    });

    test('reminder without a time still parses', () {
      final items = CaptureParser.parse('remind me to call mom');
      final r = items.single.request;
      expect(r.type, CaptureType.reminder);
      expect(r.text, 'call mom');
      expect(r.hour, isNull);
    });
  });

  group('CaptureParser — multi-line and fallback', () {
    test('multi-line paste splits into typed items', () {
      final items = CaptureParser.parse(
          'coffee 4.50\n2h deep work\nremind me to stretch at 7am');
      expect(items, hasLength(3));
      expect(items[0].request.type, CaptureType.expense);
      expect(items[1].request.type, CaptureType.time);
      expect(items[2].request.type, CaptureType.reminder);
    });

    test('semicolons split like newlines', () {
      final items = CaptureParser.parse('coffee 4.50; 30 min reading');
      expect(items, hasLength(2));
      expect(items[0].request.type, CaptureType.expense);
      expect(items[1].request.type, CaptureType.time);
    });

    test('receipt noise rows are dropped, priced rows kept', () {
      final items = CaptureParser.parse(
          'ESPRESSO 3.20\nCROISSANT 4.10\nSUBTOTAL 7.30\nTAX 0.66\nTOTAL 7.96');
      expect(items, hasLength(2));
      expect(items.every((i) => i.request.type == CaptureType.expense), isTrue);
      expect(items[0].request.amount, 3.20);
      expect(items[1].request.amount, 4.10);
    });

    test('free thought falls back to idea, never empty', () {
      final items =
          CaptureParser.parse('what if the weekly review had a streak');
      expect(items, hasLength(1));
      expect(items.single.request.type, CaptureType.idea);
      expect(items.single.confidence, lessThan(0.5));
    });

    test('all-noise input still returns something', () {
      final items = CaptureParser.parse('SUBTOTAL 12.00');
      expect(items, hasLength(1));
      expect(items.single.request.type, CaptureType.idea);
    });

    test('blank input returns nothing', () {
      expect(CaptureParser.parse('   '), isEmpty);
    });
  });
}

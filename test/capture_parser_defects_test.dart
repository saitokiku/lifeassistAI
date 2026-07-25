import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/capture/capture_parser.dart';
import 'package:life_dashboard/core/capture/capture_request.dart';

/// Regression tests for the four capture-parser defects found in review.
/// Each `test` name states the behaviour that used to be wrong.
void main() {
  group('thousands separators (used to fall through to Idea)', () {
    test(r'"$1,200 rent" is a $1200 expense', () {
      final r = CaptureParser.parse(r'$1,200 rent').single.request;
      expect(r.type, CaptureType.expense);
      expect(r.amount, 1200);
      expect(r.text, 'rent');
    });

    test(r'a pasted bank line parses', () {
      final r =
          CaptureParser.parse(r'$1,234.56 WHOLE FOODS MKT').single.request;
      expect(r.type, CaptureType.expense);
      expect(r.amount, 1234.56);
      expect(r.text, 'WHOLE FOODS MKT');
    });

    test('European grouping "1.234,56 €" parses', () {
      final r = CaptureParser.parse('spent 1.234,56 on rent').single.request;
      expect(r.type, CaptureType.expense);
      expect(r.amount, 1234.56);
    });

    test('grouping and decimals are not confused', () {
      expect(CaptureParser.parse(r'$1,200').single.request.amount, 1200);
      expect(CaptureParser.parse(r'$1,20').single.request.amount, 1.20);
      expect(CaptureParser.parse(r'$1.200').single.request.amount, 1200);
    });
  });

  group('a line with both a duration and an amount yields both', () {
    test('"coffee 4.50 and 2h deep work" gives a time AND an expense', () {
      final items = CaptureParser.parse('coffee 4.50 and 2h deep work');
      expect(items, hasLength(2));
      final time = items.firstWhere((i) => i.request.type == CaptureType.time);
      final expense =
          items.firstWhere((i) => i.request.type == CaptureType.expense);
      expect(time.request.hours, 2);
      expect(time.request.text, 'deep work');
      expect(expense.request.amount, 4.50);
      expect(expense.request.text, 'coffee');
    });

    test(r'"spent 2 hours and $40 on parts" keeps the $40', () {
      final items = CaptureParser.parse(r'spent 2 hours and $40 on parts');
      expect(items.map((i) => i.request.type),
          containsAll([CaptureType.time, CaptureType.expense]));
      expect(
        items.firstWhere((i) => i.request.type == CaptureType.expense).request
            .amount,
        40,
      );
    });
  });

  group('times are read, never invented', () {
    test('"remind me to buy 2 apples" keeps the 2 and sets no time', () {
      final r = CaptureParser.parse('remind me to buy 2 apples').single.request;
      expect(r.type, CaptureType.reminder);
      expect(r.text, 'buy 2 apples');
      expect(r.hour, isNull);
    });

    test('"remind me to call mom in 5 minutes" keeps its words', () {
      final r = CaptureParser.parse('remind me to call mom in 5 minutes')
          .single
          .request;
      expect(r.text, 'call mom in 5 minutes');
      expect(r.hour, isNull);
    });

    test('a marked time is still read, even after a bare number', () {
      final r = CaptureParser.parse('remind me to buy 2 apples at 7am')
          .single
          .request;
      expect(r.text, 'buy 2 apples');
      expect(r.hour, 7);
      expect(r.minute, 0);
    });

    test('24h "at 19:30" and bare "19:30" both read', () {
      expect(
          CaptureParser.parse('remind me to stretch at 19:30').single.request
              .hour,
          19);
      expect(
          CaptureParser.parse('remind me to stretch 19:30').single.request
              .minute,
          30);
    });

    test('nonsense times are ignored, not clamped', () {
      final r =
          CaptureParser.parse('remind me to check 99:99').single.request;
      expect(r.hour, isNull);
    });
  });

  group('prose is never silently dropped', () {
    test('"Total rethink of the launch plan" survives a multi-line paste',
        () {
      final items = CaptureParser.parse(
          'coffee 4.50\nTotal rethink of the launch plan');
      expect(items, hasLength(2));
      expect(items.last.request.type, CaptureType.idea);
      expect(items.last.request.text, 'Total rethink of the launch plan');
    });

    test('"Cash flow ideas for next quarter" survives', () {
      final items = CaptureParser.parse(
          '2h admin\nCash flow ideas for next quarter');
      expect(items.map((i) => i.request.text),
          contains('Cash flow ideas for next quarter'));
    });

    test('but real receipt summary rows are still dropped', () {
      final items = CaptureParser.parse(
          'ESPRESSO 3.20\nCROISSANT 4.10\nSUBTOTAL 7.30\nTOTAL 7.96');
      expect(items, hasLength(2));
      expect(items.every((i) => i.request.type == CaptureType.expense), isTrue);
    });
  });

  group('bare numbers are not money', () {
    test(r'"2 for 1 deal at the store" is an idea, not a $2 expense', () {
      final r =
          CaptureParser.parse('2 for 1 deal at the store').single.request;
      expect(r.type, CaptureType.idea);
    });

    test('"call room 12" stays an idea', () {
      expect(CaptureParser.parse('call room 12').single.request.type,
          CaptureType.idea);
    });
  });
}

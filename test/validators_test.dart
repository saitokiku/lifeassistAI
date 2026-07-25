import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/utils/validation.dart';

void main() {
  group('Validators.normalizeDecimal', () {
    test('plain dot decimals pass through', () {
      expect(Validators.normalizeDecimal('4.50'), '4.50');
      expect(Validators.normalizeDecimal('1200'), '1200');
      expect(Validators.normalizeDecimal(' 12 '), '12');
    });

    test('comma decimal converts — the 100x keyboard bug', () {
      // On European/Latin American keyboards the decimal key types ','.
      // Dropping it turned "4,50" into 450 — a silent 100x error.
      expect(Validators.normalizeDecimal('4,50'), '4.50');
      expect(Validators.normalizeDecimal('0,99'), '0.99');
      expect(Validators.normalizeDecimal('1,5'), '1.5');
      expect(Validators.normalizeDecimal('-4,50'), '-4.50');
    });

    test('comma grouping strips — pasted US amounts', () {
      expect(Validators.normalizeDecimal('1,200'), '1200');
      expect(Validators.normalizeDecimal('1,234,567'), '1234567');
    });

    test('mixed separators: the last one is the decimal point', () {
      expect(Validators.normalizeDecimal('1,234.56'), '1234.56');
      expect(Validators.normalizeDecimal('1.234,56'), '1234.56');
      expect(Validators.normalizeDecimal('12.345.678,90'), '12345678.90');
    });
  });

  group('Validators.number', () {
    test('accepts both decimal conventions', () {
      expect(Validators.number('4.50'), isNull);
      expect(Validators.number('4,50'), isNull);
      expect(Validators.number('1,200'), isNull);
    });

    test('rejects non-numbers and absurd magnitudes', () {
      expect(Validators.number('abc'), isNotNull);
      expect(Validators.number(''), isNotNull);
      expect(Validators.number('9999999999'), isNotNull); // > maxMagnitude
    });
  });

  group('Validators.parseNumber / tryParseNumber', () {
    test('parse both conventions to the same value', () {
      expect(Validators.parseNumber('4,50'), 4.50);
      expect(Validators.parseNumber('4.50'), 4.50);
      expect(Validators.parseNumber('1,200'), 1200);
      expect(Validators.parseNumber('1.234,56'), 1234.56);
      expect(Validators.tryParseNumber('4,50'), 4.50);
      expect(Validators.tryParseNumber(''), isNull);
      expect(Validators.tryParseNumber(null), isNull);
    });
  });

  group('positive / nonNegative still hold under normalization', () {
    test('bounds apply to the normalized value', () {
      expect(Validators.positiveNumber('0,50'), isNull);
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.nonNegativeNumber('-0,50'), isNotNull);
      expect(Validators.optionalNumber(''), isNull);
      expect(Validators.optionalNumber('4,50'), isNull);
    });
  });
}

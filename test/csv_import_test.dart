import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/features/money/data/csv_import.dart';

/// Statement imports carry real money data — the parsing rules get pinned
/// here across the formats banks actually export.
void main() {
  group('CsvImport.parse', () {
    test('comma CSV parses into a table', () {
      final table = CsvImport.parse(
          'Date,Description,Amount\n2026-07-01,Coffee,-4.50\n');
      expect(table, hasLength(2));
      expect(table.first, ['Date', 'Description', 'Amount']);
    });

    test('semicolon CSV picks the right delimiter', () {
      final table = CsvImport.parse(
          'Date;Description;Amount\n01.07.2026;Kaffee;-4,50\n');
      expect(table.first, hasLength(3));
    });

    test('junk yields empty', () {
      expect(CsvImport.parse(''), isEmpty);
    });
  });

  group('CsvImport.tryParseDate', () {
    test('ISO', () {
      expect(CsvImport.tryParseDate('2026-07-04'), DateTime(2026, 7, 4));
    });

    test('US slashes month-first', () {
      expect(CsvImport.tryParseDate('07/04/2026'), DateTime(2026, 7, 4));
    });

    test('day-first when month-first is impossible', () {
      expect(CsvImport.tryParseDate('25/06/2026'), DateTime(2026, 6, 25));
    });

    test('dotted European', () {
      expect(CsvImport.tryParseDate('04.07.2026'), DateTime(2026, 7, 4));
    });

    test('named month', () {
      expect(CsvImport.tryParseDate('Jul 4, 2026'), DateTime(2026, 7, 4));
    });

    test('two-digit year', () {
      expect(CsvImport.tryParseDate('07/04/26'), DateTime(2026, 7, 4));
    });

    test('rollover dates rejected', () {
      expect(CsvImport.tryParseDate('2026-02-30'), isNull);
    });
  });

  group('CsvImport.tryParseAmount', () {
    test('plain and signed', () {
      expect(CsvImport.tryParseAmount('12.50'), 12.50);
      expect(CsvImport.tryParseAmount('-12.50'), -12.50);
    });

    test('currency symbols and thousands separators', () {
      expect(CsvImport.tryParseAmount(r'-$1,234.56'), -1234.56);
    });

    test('accounting parentheses mean negative', () {
      expect(CsvImport.tryParseAmount('(45.00)'), -45.00);
    });

    test('European decimal comma', () {
      expect(CsvImport.tryParseAmount('1.234,56 €'), 1234.56);
    });

    test('garbage is null', () {
      expect(CsvImport.tryParseAmount('n/a'), isNull);
    });
  });

  group('CsvImport.guessMapping', () {
    test('reads header names', () {
      final table = CsvImport.parse(
          'Posted Date,Payee,Amount\n2026-07-01,Coffee,-4.50\n');
      final guess = CsvImport.guessMapping(table);
      expect(guess.date, 0);
      expect(guess.description, 1);
      expect(guess.amount, 2);
    });

    test('sniffs types when headers are absent', () {
      final table = CsvImport.parse('2026-07-01,Coffee,-4.50\n');
      final guess = CsvImport.guessMapping(table);
      expect(guess.date, 0);
      expect(guess.amount, 2);
      expect(guess.description, 1);
    });
  });

  group('CsvImport.extract', () {
    test('negative-majority convention: debits negative, deposits skipped',
        () {
      final table = CsvImport.parse('Date,Desc,Amount\n'
          '2026-07-01,Coffee,-4.50\n'
          '2026-07-02,Rent,-1200.00\n'
          '2026-07-03,Paycheck,2500.00\n');
      final result = CsvImport.extract(
        table,
        dateColumn: 0,
        amountColumn: 2,
        descriptionColumn: 1,
      );
      expect(result.rows, hasLength(2));
      expect(result.rows.first.amount, 4.50); // sign normalized to spend
      expect(result.skippedDeposits, 1);
    });

    test('positive-spend convention passes through', () {
      final table = CsvImport.parse('Date,Desc,Amount\n'
          '2026-07-01,Coffee,4.50\n'
          '2026-07-02,Lunch,12.00\n');
      final result = CsvImport.extract(
        table,
        dateColumn: 0,
        amountColumn: 2,
        descriptionColumn: 1,
      );
      expect(result.rows, hasLength(2));
      expect(result.rows.last.amount, 12.00);
      expect(result.skippedDeposits, 0);
    });

    test('unparsable rows are counted, not silently dropped', () {
      final table = CsvImport.parse('Date,Desc,Amount\n'
          'not-a-date,Coffee,-4.50\n'
          '2026-07-02,Lunch,-12.00\n');
      final result = CsvImport.extract(
        table,
        dateColumn: 0,
        amountColumn: 2,
        descriptionColumn: 1,
      );
      expect(result.rows, hasLength(1));
      expect(result.skippedUnparsed, 1);
    });
  });

  test('duplicateKey normalizes case and cents', () {
    final a = CsvImport.duplicateKey(
        dateKey: '2026-07-01', amount: 4.5, description: 'Coffee ');
    final b = CsvImport.duplicateKey(
        dateKey: '2026-07-01', amount: 4.50, description: 'coffee');
    expect(a, b);
  });
}

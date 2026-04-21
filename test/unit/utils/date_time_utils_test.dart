import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('mr');
    await initializeDateFormatting('en');
  });

  group('formatDateShort', () {
    final date = DateTime(2024, 4, 22); // 22 April 2024

    test('returns English format "MMMM d" for en locale', () {
      // Arrange + Act
      final result = formatDateShort(date, 'en');
      // Assert
      expect(result, 'April 22');
    });

    test(
      'returns Marathi format "d MMMM" with Marathi numerals for mr locale',
      () {
        // Arrange + Act
        final result = formatDateShort(date, 'mr');
        // Assert — day 22 → २२, month in Marathi
        expect(result, contains('२२')); // Marathi numerals for 22
      },
    );

    test('returns English format for unknown locale', () {
      final result = formatDateShort(date, 'hi');
      // hi is not mr, so falls through to English branch
      expect(result, 'April 22');
    });
  });

  group('formatDateLong', () {
    final date = DateTime(2024, 1, 5); // 5 January 2024

    test('returns "MMMM d, yyyy" for en locale', () {
      final result = formatDateLong(date, 'en');
      expect(result, 'January 5, 2024');
    });

    test('contains Marathi numerals for year and day for mr locale', () {
      final result = formatDateLong(date, 'mr');
      // Day 5 → ५, year 2024 → २०२४
      expect(result, contains('५'));
      expect(result, contains('२०२४'));
    });
  });

  group('formatDateWithDay', () {
    // Monday 22 April 2024
    final date = DateTime(2024, 4, 22);

    test('returns weekday in result for en locale', () {
      final result = formatDateWithDay(date, 'en');
      expect(result, contains('Monday'));
      expect(result, contains('April'));
      expect(result, contains('2024'));
    });

    test('converts numerals to Marathi for mr locale', () {
      final result = formatDateWithDay(date, 'mr');
      expect(result, contains('२२'));
      expect(result, contains('२०२४'));
    });
  });

  group('formatMonthYear', () {
    final date = DateTime(2024, 4, 1);

    test('returns "MMMM yyyy" for en locale', () {
      final result = formatMonthYear(date, 'en');
      expect(result, 'April 2024');
    });

    test('converts year to Marathi numerals for mr locale', () {
      final result = formatMonthYear(date, 'mr');
      expect(result, contains('२०२४'));
    });
  });
}

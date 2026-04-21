import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

void main() {
  group('toMarathiNumerals', () {
    test('converts all ten English digits to Marathi equivalents', () {
      expect(toMarathiNumerals('0123456789'), '०१२३४५६७८९');
    });

    test('leaves non-numeric characters unchanged', () {
      expect(toMarathiNumerals('Day 1'), 'Day १');
    });

    test('handles empty string without error', () {
      expect(toMarathiNumerals(''), '');
    });

    test('converts numerals embedded in a percentage string', () {
      expect(toMarathiNumerals('50%'), '५०%');
    });
  });

  group('formatNumberLocalized', () {
    group('Marathi locale', () {
      test('pads single-digit numbers when pad is true', () {
        expect(formatNumberLocalized(5, 'mr', pad: true), '०५');
      });

      test('does not pad when pad is false', () {
        expect(formatNumberLocalized(12, 'mr', pad: false), '१२');
      });

      test('returns Marathi numerals for zero', () {
        expect(formatNumberLocalized(0, 'mr', pad: false), '०');
      });

      test('converts large numbers correctly', () {
        expect(formatNumberLocalized(10800, 'mr', pad: false), '१०८००');
      });

      test('returns empty string for null input', () {
        expect(formatNumberLocalized(null, 'mr'), '');
      });
    });

    group('English locale', () {
      test('pads single-digit numbers when pad is true', () {
        expect(formatNumberLocalized(5, 'en', pad: true), '05');
      });

      test('does not pad when pad is false', () {
        expect(formatNumberLocalized(12, 'en', pad: false), '12');
      });

      test('returns English numerals for zero', () {
        expect(formatNumberLocalized(0, 'en', pad: false), '0');
      });

      test('returns empty string for null input', () {
        expect(formatNumberLocalized(null, 'en'), '');
      });
    });
  });
}

import 'package:flutter/material.dart';
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

      test('converts large numbers correctly with Indian formatting', () {
        expect(formatNumberLocalized(10800, 'mr', pad: false), '१०,८००');
        expect(formatNumberLocalized(123456, 'mr', pad: false), '१,२३,४५६');
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

      test('formats large numbers with commas', () {
        expect(formatNumberLocalized(123456, 'en', pad: false), '1,23,456');
      });

      test('returns English numerals for zero', () {
        expect(formatNumberLocalized(0, 'en', pad: false), '0');
      });

      test('returns empty string for null input', () {
        expect(formatNumberLocalized(null, 'en'), '');
      });
    });
  });

  group('formatLocalizedText', () {
    test('converts to Marathi numerals for mr locale', () {
      expect(formatLocalizedText('Adhyay 1', const Locale('mr')), 'Adhyay १');
    });

    test('converts to Marathi numerals for en_MR locale', () {
      expect(
        formatLocalizedText('Adhyay 1', const Locale('en', 'MR')),
        'Adhyay १',
      );
    });

    test('keeps English numerals for en locale', () {
      expect(formatLocalizedText('Adhyay 1', const Locale('en')), 'Adhyay 1');
    });
  });
}

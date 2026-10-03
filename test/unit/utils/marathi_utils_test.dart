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

    test('keeps English numerals for en_MR locale', () {
      expect(
        formatLocalizedText('Adhyay 1', const Locale('en', 'MR')),
        'Adhyay 1',
      );
    });

    test('keeps English numerals for en locale', () {
      expect(formatLocalizedText('Adhyay 1', const Locale('en')), 'Adhyay 1');
    });
  });
  group('formatNumberLocalized - String input', () {
    test('accepts a parseable String input and converts', () {
      expect(formatNumberLocalized('12', 'en', pad: false), '12');
      expect(formatNumberLocalized('5', 'mr', pad: true), '०५');
    });

    test('falls back to toString() for unparseable String', () {
      // When num.tryParse fails, it falls back to number.toString()
      expect(formatNumberLocalized('abc', 'en', pad: false), 'abc');
    });
  });

  group('toEnglishNumerals', () {
    test('converts all Marathi digits to English equivalents', () {
      expect(toEnglishNumerals('०१२३४५६७८९'), '0123456789');
    });

    test('leaves non-numeric Marathi characters unchanged', () {
      expect(toEnglishNumerals('Day १'), 'Day 1');
    });

    test('handles empty string without error', () {
      expect(toEnglishNumerals(''), '');
    });
  });

  group('formatDistanceLocalized', () {
    test('returns English formatted distance for en', () {
      expect(formatDistanceLocalized(3.14159, 'en'), '3.1');
    });

    test('returns Marathi numeral distance for mr', () {
      expect(formatDistanceLocalized(3.14159, 'mr'), '३.१');
    });

    test('returns 0.0 formatted for zero distance', () {
      expect(formatDistanceLocalized(0.0, 'en'), '0.0');
    });
  });

  group('localizedDistanceUnitLabel', () {
    test('returns miles label in English', () {
      expect(localizedDistanceUnitLabel('mi', 'en'), 'miles');
    });

    test('returns km label unchanged in English', () {
      expect(localizedDistanceUnitLabel('km', 'en'), 'km');
    });

    test('returns Marathi label for miles', () {
      expect(localizedDistanceUnitLabel('mi', 'mr'), 'मैल');
    });

    test('returns Marathi label for km', () {
      expect(localizedDistanceUnitLabel('km', 'mr'), 'किमी');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/phone_utils.dart';

void main() {
  group('splitPhone', () {
    test('splits a stored number on a known country code', () {
      expect(splitPhone('+911234567890', '+1'), (
        code: '+91',
        number: '1234567890',
      ));
      expect(splitPhone('+15851234567', '+91'), (
        code: '+1',
        number: '5851234567',
      ));
      expect(splitPhone('+971501234567', '+1'), (
        code: '+971',
        number: '501234567',
      ));
    });

    test('prefers the longest matching code', () {
      // +971 must win over the +9... / +1 style prefixes.
      expect(splitPhone('+971501234567', '+91').code, '+971');
    });

    test('uses the default code for a number stored without one', () {
      expect(splitPhone('5851234567', '+91'), (
        code: '+91',
        number: '5851234567',
      ));
    });

    test('uses the default code and an empty number for null or empty', () {
      expect(splitPhone(null, '+1'), (code: '+1', number: ''));
      expect(splitPhone('  ', '+44'), (code: '+44', number: ''));
    });

    test('keeps an unknown +code number whole under the default code', () {
      expect(splitPhone('+8801234567890', '+1'), (
        code: '+1',
        number: '+8801234567890',
      ));
    });
  });

  group('joinPhone', () {
    test('concatenates the trimmed code and number', () {
      expect(joinPhone(' +91 ', ' 1234567890 '), '+911234567890');
    });

    test('returns null when the number has no digits', () {
      expect(joinPhone('+91', ''), isNull);
      expect(joinPhone('+91', '  '), isNull);
    });
  });

  group('isValidCountryCode', () {
    test('accepts a plus and one to four digits', () {
      for (final code in ['+1', '+91', '+971', '+1242']) {
        expect(isValidCountryCode(code), isTrue, reason: code);
      }
    });

    test('rejects everything else', () {
      for (final code in ['', '91', '+', '+12345', '+9a', '1+']) {
        expect(isValidCountryCode(code), isFalse, reason: code);
      }
      expect(isValidCountryCode(null), isFalse);
    });
  });

  group('minPhoneDigits', () {
    test('is 10 by default and shorter for the countries that need it', () {
      expect(minPhoneDigits('+1'), 10);
      expect(minPhoneDigits('+91'), 10);
      expect(minPhoneDigits('+65'), 8);
      expect(minPhoneDigits('+27'), 9);
      expect(minPhoneDigits('+971'), 9);
    });
  });

  group('phonesMatch', () {
    test('matches identical numbers regardless of formatting', () {
      expect(phonesMatch('+1 (585) 123-4567', '+15851234567'), isTrue);
    });

    test('matches a number stored with and without its country code', () {
      expect(phonesMatch('+15851234567', '5851234567'), isTrue);
      expect(phonesMatch('5851234567', '+15851234567'), isTrue);
    });

    test('does not match different numbers', () {
      expect(phonesMatch('+15851234567', '+15851234568'), isFalse);
    });

    test('does not match on a short or empty number', () {
      expect(phonesMatch('1234567', '+11234567'), isFalse);
      expect(phonesMatch('', '+15851234567'), isFalse);
      expect(phonesMatch(null, null), isFalse);
    });
  });
}

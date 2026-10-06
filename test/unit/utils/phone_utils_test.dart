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

    group('a number stored without a plus (country code + number digits)', () {
      test('splits on a known code when the rest is a full number', () {
        expect(splitPhone('14255551234', '+91'), (
          code: '+1',
          number: '4255551234',
        ));
        expect(splitPhone('919876543210', '+1'), (
          code: '+91',
          number: '9876543210',
        ));
        expect(splitPhone('971501234567', '+1'), (
          code: '+971',
          number: '501234567',
        ));
        expect(splitPhone('447911123456', '+1'), (
          code: '+44',
          number: '7911123456',
        ));
      });

      test('keeps a 10-digit number saved before country codes whole, even '
          'when it starts with a known code', () {
        for (final legacy in ['4255551234', '6505551234', '9112345678']) {
          expect(splitPhone(legacy, '+1'), (code: '+1', number: legacy));
        }
      });

      test('keeps a number whole when too few digits follow the code', () {
        // Starts with 91 but only nine digits remain: not an Indian number.
        expect(splitPhone('91987654321', '+1'), (
          code: '+1',
          number: '91987654321',
        ));
      });

      test('keeps a number that does not start with a known code whole', () {
        expect(splitPhone('85212345678', '+1'), (
          code: '+1',
          number: '85212345678',
        ));
      });
    });

    test('keeps an unknown +code number whole under the default code', () {
      expect(splitPhone('+8801234567890', '+1'), (
        code: '+1',
        number: '+8801234567890',
      ));
    });
  });

  group('joinPhone', () {
    test('concatenates the code and number as digits, with no plus', () {
      expect(joinPhone(' +91 ', ' 1234567890 '), '911234567890');
      expect(joinPhone('+1', '4255551234'), '14255551234');
    });

    test('drops spaces, dashes and brackets', () {
      expect(joinPhone('+1', '(425) 555-1234'), '14255551234');
      expect(joinPhone('+91', '98765 43210'), '919876543210');
    });

    test('splits back into what was joined', () {
      for (final (code, number) in [
        ('+1', '4255551234'),
        ('+91', '9876543210'),
        ('+971', '501234567'),
        ('+44', '7911123456'),
      ]) {
        expect(splitPhone(joinPhone(code, number), '+1'), (
          code: code,
          number: number,
        ));
      }
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

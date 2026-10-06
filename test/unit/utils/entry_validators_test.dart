import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/entry_validators.dart';

void main() {
  group('isValidEmail', () {
    test('accepts ordinary addresses, ignoring surrounding spaces', () {
      expect(isValidEmail('jane@example.com'), isTrue);
      expect(isValidEmail('  jane.doe-1@mail.example.org '), isTrue);
    });

    test('rejects text that is not an address', () {
      for (final bad in [
        '',
        'jane',
        'jane@',
        '@example.com',
        'a@b',
        'a b@c.com',
      ]) {
        expect(isValidEmail(bad), isFalse, reason: bad);
      }
    });
  });

  group('parsePledgeAmount', () {
    test('parses whole and fractional amounts, ignoring spaces', () {
      expect(parsePledgeAmount('25'), 25);
      expect(parsePledgeAmount(' 50.5 '), 50.5);
    });

    test('accepts the limits 0 and 1,000,000', () {
      expect(parsePledgeAmount('0'), 0);
      expect(parsePledgeAmount('1000000'), 1000000);
    });

    test('rejects negative, over-limit and non-finite amounts', () {
      for (final bad in [
        '-1',
        '1000000.01',
        '1000001',
        'NaN',
        'Infinity',
        '-Infinity',
        'abc',
        '',
      ]) {
        expect(parsePledgeAmount(bad), isNull, reason: bad);
      }
    });
  });
}

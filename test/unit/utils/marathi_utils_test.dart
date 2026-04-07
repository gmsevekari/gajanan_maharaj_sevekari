import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

void main() {
  group('marathi_utils', () {
    test('toMarathiNumerals should convert English digits to Marathi digits', () {
      expect(toMarathiNumerals('0123456789'), '०१२३४५६७८९');
    });

    test('toMarathiNumerals should handle mixed alphanumeric strings', () {
      expect(toMarathiNumerals('Phone: 9876543210'), 'Phone: ९८७६५४३२१०');
      expect(toMarathiNumerals('Version 1.0.25'), 'Version १.०.२५');
    });

    test('toMarathiNumerals should return an empty string when given an empty string', () {
      expect(toMarathiNumerals(''), '');
    });

    test('toMarathiNumerals should handle strings without digits', () {
      expect(toMarathiNumerals('Hello World'), 'Hello World');
    });

    test('toMarathiNumerals should not affect already Marathi digits', () {
      expect(toMarathiNumerals('९८७६'), '९८७६');
    });
  });
}

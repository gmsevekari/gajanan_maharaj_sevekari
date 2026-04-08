import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

void main() {
  group('MarathiUtils', () {
    test('toMarathiNumerals should convert English digits to Marathi', () {
      expect(toMarathiNumerals('1234567890'), '१२३४५६७८९०');
      expect(toMarathiNumerals('Day 1'), 'Day १');
    });

    test('formatNumberLocalized should pad and localize for Marathi', () {
      expect(formatNumberLocalized(5, 'mr', pad: true), '०५');
      expect(formatNumberLocalized(12, 'mr', pad: false), '१२');
    });

    test('formatNumberLocalized should return English for other locales', () {
      expect(formatNumberLocalized(5, 'en', pad: true), '05');
      expect(formatNumberLocalized(12, 'en', pad: false), '12');
    });
  });
}

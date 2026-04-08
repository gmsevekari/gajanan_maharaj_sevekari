import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';

void main() {
  group('ParayanTypeExtensions', () {
    test('daysCount should return 1 for oneDay type', () {
      expect(ParayanType.oneDay.daysCount, 1);
    });

    test('daysCount should return 3 for threeDay type', () {
      expect(ParayanType.threeDay.daysCount, 3);
    });

    test('daysCount should return 1 for guruPushya type', () {
      expect(ParayanType.guruPushya.daysCount, 1);
    });
  });
}

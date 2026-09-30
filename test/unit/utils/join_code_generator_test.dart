import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/join_code_generator.dart';

void main() {
  group('generateJoinCode', () {
    test('returns a 6-character code', () {
      expect(generateJoinCode().length, 6);
    });

    test('only uses uppercase letters and digits', () {
      final code = generateJoinCode();
      expect(RegExp(r'^[A-Z0-9]{6}$').hasMatch(code), isTrue);
    });

    test('generates different codes across calls', () {
      final codes = List.generate(20, (_) => generateJoinCode());
      expect(codes.toSet().length, greaterThan(1));
    });
  });
}

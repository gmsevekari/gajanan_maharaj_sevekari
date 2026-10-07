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

  group('joinCodeAfterEdit', () {
    String fixed() => 'NEW123';

    test('is no code when the requirement is off', () {
      expect(
        joinCodeAfterEdit(
          wasRequired: true,
          currentCode: 'OLD999',
          nowRequired: false,
          generate: fixed,
        ),
        isNull,
      );
      expect(
        joinCodeAfterEdit(
          wasRequired: false,
          currentCode: null,
          nowRequired: false,
          generate: fixed,
        ),
        isNull,
      );
    });

    test('keeps the code when the requirement stays on', () {
      expect(
        joinCodeAfterEdit(
          wasRequired: true,
          currentCode: 'OLD999',
          nowRequired: true,
          generate: fixed,
        ),
        'OLD999',
      );
    });

    test('makes a new code when the requirement is switched on', () {
      expect(
        joinCodeAfterEdit(
          wasRequired: false,
          currentCode: null,
          nowRequired: true,
          generate: fixed,
        ),
        'NEW123',
      );
    });

    test('makes a new code, not the old one, when switched on again', () {
      // A code left behind from before the requirement was switched off must
      // not come back.
      expect(
        joinCodeAfterEdit(
          wasRequired: false,
          currentCode: 'OLD999',
          nowRequired: true,
          generate: fixed,
        ),
        'NEW123',
      );
    });

    test('makes a code when the requirement is on but the code is missing or '
        'blank', () {
      for (final broken in [null, '', '  ']) {
        expect(
          joinCodeAfterEdit(
            wasRequired: true,
            currentCode: broken,
            nowRequired: true,
            generate: fixed,
          ),
          'NEW123',
        );
      }
    });

    test('generates a real six-character code by default', () {
      final code = joinCodeAfterEdit(
        wasRequired: false,
        currentCode: null,
        nowRequired: true,
      );

      expect(code, matches(RegExp(r'^[A-Z0-9]{6}$')));
    });
  });
}

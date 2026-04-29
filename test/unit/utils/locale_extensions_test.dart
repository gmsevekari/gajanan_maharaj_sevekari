import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';

void main() {
  group('LocaleContent extension', () {
    test('useMarathiContent is true for mr', () {
      expect(const Locale('mr').useMarathiContent, isTrue);
    });

    test('useMarathiContent is true for en_MR', () {
      expect(const Locale('en', 'MR').useMarathiContent, isTrue);
    });

    test('useMarathiContent is false for en', () {
      expect(const Locale('en').useMarathiContent, isFalse);
    });

    test('useMarathiContent is false for hi', () {
      expect(const Locale('hi').useMarathiContent, isFalse);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';

void main() {
  group('LocaleContent.useMarathiContent', () {
    test('is true for mr', () {
      expect(const Locale('mr').useMarathiContent, isTrue);
    });

    test('is true for en_MR', () {
      expect(const Locale('en', 'MR').useMarathiContent, isTrue);
    });

    test('is false for en', () {
      expect(const Locale('en').useMarathiContent, isFalse);
    });

    test('is false for hi', () {
      expect(const Locale('hi').useMarathiContent, isFalse);
    });

    test('is false for en with unrelated country code', () {
      expect(const Locale('en', 'US').useMarathiContent, isFalse);
    });
  });

  group('LocaleContent.localizedContent', () {
    const enText = 'Gajanan Vijay Granth';
    const mrText = 'गजानन विजय ग्रंथ';

    test('returns Marathi text for mr locale', () {
      expect(const Locale('mr').localizedContent(enText, mrText), mrText);
    });

    test('returns Marathi text for en_MR locale', () {
      expect(const Locale('en', 'MR').localizedContent(enText, mrText), mrText);
    });

    test('returns English text for en locale', () {
      expect(const Locale('en').localizedContent(enText, mrText), enText);
    });

    test('falls back to English when mrText is empty and locale is mr', () {
      expect(const Locale('mr').localizedContent(enText, ''), enText);
    });

    test('falls back to English when mrText is empty and locale is en_MR', () {
      expect(const Locale('en', 'MR').localizedContent(enText, ''), enText);
    });

    test('handles both strings empty gracefully', () {
      expect(const Locale('mr').localizedContent('', ''), '');
    });
  });
}

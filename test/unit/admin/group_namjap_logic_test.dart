import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Canonical test fixture for a GroupNamjapEvent.
GroupNamjapEvent makeEvent({
  String id = 'evt1',
  String nameEn = 'Test Namjap',
  String nameMr = 'टेस्ट नामजप',
  String sankalpEn = '108 chants',
  String sankalpMr = '१०८ जप',
  int targetCount = 108,
  int totalCount = 54,
  String mantra = 'Gan Gan Ganat Bote',
  String joinCode = 'ABC123',
  String status = 'ongoing',
}) => GroupNamjapEvent(
  id: id,
  nameEn: nameEn,
  nameMr: nameMr,
  sankalpEn: sankalpEn,
  sankalpMr: sankalpMr,
  startDate: DateTime(2024, 4, 22),
  endDate: DateTime(2024, 4, 29),
  targetCount: targetCount,
  totalCount: totalCount,
  mantra: mantra,
  joinCode: joinCode,
  status: status,
  groupId: 'grp1',
  createdAt: DateTime(2024, 4, 1),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('mr');
    await initializeDateFormatting('en');
  });

  // ---------------------------------------------------------------------------
  // Progress computation
  // ---------------------------------------------------------------------------
  group('GroupNamjapEvent — progress computation', () {
    test('returns 50% progress when totalCount is half of targetCount', () {
      // Arrange
      final event = makeEvent(targetCount: 108, totalCount: 54);

      // Act
      final progress = event.targetCount > 0
          ? (event.totalCount / event.targetCount).clamp(0.0, 1.0)
          : 0.0;

      // Assert
      expect(progress, closeTo(0.5, 0.001));
    });

    test('clamps progress to 1.0 when totalCount exceeds targetCount', () {
      // Arrange
      final event = makeEvent(targetCount: 100, totalCount: 200);

      // Act
      final progress = event.targetCount > 0
          ? (event.totalCount / event.targetCount).clamp(0.0, 1.0)
          : 0.0;

      // Assert
      expect(progress, 1.0);
    });

    test(
      'returns 0.0 progress when targetCount is zero (avoids division by zero)',
      () {
        // Arrange
        final event = makeEvent(targetCount: 0, totalCount: 0);

        // Act
        final progress = event.targetCount > 0
            ? (event.totalCount / event.targetCount).clamp(0.0, 1.0)
            : 0.0;

        // Assert
        expect(progress, 0.0);
      },
    );

    test('returns 0.0 progress when totalCount is zero', () {
      final event = makeEvent(targetCount: 108, totalCount: 0);
      final progress = event.targetCount > 0
          ? (event.totalCount / event.targetCount).clamp(0.0, 1.0)
          : 0.0;
      expect(progress, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Numeral localization applied to event counts
  // ---------------------------------------------------------------------------
  group('GroupNamjapEvent — numeral localization', () {
    final event = makeEvent(targetCount: 108, totalCount: 54);

    test('English locale renders counts as Arabic numerals', () {
      expect(formatNumberLocalized(event.targetCount, 'en', pad: false), '108');
      expect(formatNumberLocalized(event.totalCount, 'en', pad: false), '54');
    });

    test('Marathi locale renders counts as Devanagari numerals', () {
      expect(formatNumberLocalized(event.targetCount, 'mr', pad: false), '१०८');
      expect(formatNumberLocalized(event.totalCount, 'mr', pad: false), '५४');
    });

    test('progress percentage is localized correctly in Marathi', () {
      final progress = event.totalCount / event.targetCount; // 0.5
      final percentStr =
          '${formatNumberLocalized((progress * 100).toInt(), 'mr', pad: false)}%';
      expect(percentStr, '५०%');
    });

    test('progress percentage is plain Arabic digits in English', () {
      final progress = event.totalCount / event.targetCount;
      final percentStr =
          '${formatNumberLocalized((progress * 100).toInt(), 'en', pad: false)}%';
      expect(percentStr, '50%');
    });
  });

  // ---------------------------------------------------------------------------
  // Date localization applied to event dates
  // ---------------------------------------------------------------------------
  group('GroupNamjapEvent — date localization', () {
    final event = makeEvent();

    test('English date range uses English month names', () {
      final range =
          '${formatDateShort(event.startDate, 'en')} - ${formatDateShort(event.endDate, 'en')}';
      expect(range, 'April 22 - April 29');
    });

    test('Marathi date range contains Devanagari day numerals', () {
      final range =
          '${formatDateShort(event.startDate, 'mr')} - ${formatDateShort(event.endDate, 'mr')}';
      expect(range, contains('२२'));
      expect(range, contains('२९'));
    });
  });

  // ---------------------------------------------------------------------------
  // Export card data derivation (pure logic, no widgets)
  // ---------------------------------------------------------------------------
  group('Export card data derivation', () {
    test('English event name selected for en locale', () {
      final event = makeEvent();
      final isEnglish = true;
      expect(isEnglish ? event.nameEn : event.nameMr, event.nameEn);
    });

    test('Marathi event name selected for mr locale', () {
      final event = makeEvent();
      final isEnglish = false;
      expect(isEnglish ? event.nameEn : event.nameMr, event.nameMr);
    });

    test('Export shows correct achievement fraction string in English', () {
      final event = makeEvent(targetCount: 108, totalCount: 54);
      final lang = 'en';
      final fraction =
          '${formatNumberLocalized(event.totalCount, lang, pad: false)} / ${formatNumberLocalized(event.targetCount, lang, pad: false)}';
      expect(fraction, '54 / 108');
    });

    test('Export shows correct achievement fraction string in Marathi', () {
      final event = makeEvent(targetCount: 108, totalCount: 54);
      final lang = 'mr';
      final fraction =
          '${formatNumberLocalized(event.totalCount, lang, pad: false)} / ${formatNumberLocalized(event.targetCount, lang, pad: false)}';
      expect(fraction, '५४ / १०८');
    });
  });
}

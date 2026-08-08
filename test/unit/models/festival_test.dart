import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/models/festival.dart';

void main() {
  group('Festival Model Tests', () {
    test('Festival.fromJson parses valid JSON correctly', () {
      final json = {
        'id': 'prakat_din_2026',
        'name_en': 'Prakat Din',
        'name_mr': 'प्रकट दिन',
        'startDate': '2026-02-20T00:00:00.000',
        'endDate': '2026-02-22T23:59:59.000',
        'themePreset': 'diwali',
      };

      final festival = Festival.fromJson(json);

      expect(festival.id, equals('prakat_din_2026'));
      expect(festival.nameEn, equals('Prakat Din'));
      expect(festival.nameMr, equals('प्रकट दिन'));
      expect(festival.startDate, equals(DateTime(2026, 2, 20)));
      expect(festival.endDate, equals(DateTime(2026, 2, 22, 23, 59, 59)));
      expect(festival.themePreset, equals(ThemePreset.diwali));
    });

    test('Festival.fromJson falls back to default values for missing or invalid JSON', () {
      final json = <String, dynamic>{};

      final festival = Festival.fromJson(json);

      expect(festival.id, equals('unknown'));
      expect(festival.nameEn, equals('Unknown'));
      expect(festival.nameMr, equals('Unknown'));
      expect(festival.themePreset, equals(ThemePreset.saffron));
    });

    test('Festival.fromJson handles invalid themePreset string gracefully', () {
      final json = {
        'id': 'test_fest',
        'themePreset': 'nonExistentPreset',
      };

      final festival = Festival.fromJson(json);
      expect(festival.themePreset, equals(ThemePreset.saffron));
    });

    test('isActive checks start date, active duration, inclusive end date, and out-of-range dates', () {
      final festival = Festival(
        id: 'fest1',
        nameEn: 'Prakat Din',
        nameMr: 'प्रकट दिन',
        startDate: DateTime(2026, 2, 20),
        endDate: DateTime(2026, 2, 22),
        themePreset: ThemePreset.saffron,
      );

      // Before start date
      expect(festival.isActive(DateTime(2026, 2, 19, 23, 59)), isFalse);

      // On start date
      expect(festival.isActive(DateTime(2026, 2, 20, 0, 0)), isTrue);

      // Middle of festival
      expect(festival.isActive(DateTime(2026, 2, 21, 15, 30)), isTrue);

      // On end date (inclusive)
      expect(festival.isActive(DateTime(2026, 2, 22, 23, 59)), isTrue);

      // After end date
      expect(festival.isActive(DateTime(2026, 2, 23, 0, 0)), isFalse);
    });
  });
}

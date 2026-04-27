import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/utils/parayan_extensions.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('mr', null);
  });

  group('ParayanEventFormatting.getSmartDate', () {
    test('returns same-day date with day of week (English)', () {
      final event = ParayanEvent(
        id: '1',
        titleEn: 'Test',
        titleMr: 'Test',
        descriptionEn: 'Test',
        descriptionMr: 'Test',
        startDate: DateTime(2026, 5, 1), // Friday
        endDate: DateTime(2026, 5, 1),
        type: ParayanType.oneDay,
        status: 'upcoming',
        reminderTimes: [],
        groupId: 'test',
        createdAt: DateTime.now(),
      );

      expect(event.getSmartDate('en', includeTime: false), 'Friday, May 1, 2026');
    });

    test('returns same-day date with day of week (Marathi)', () {
      final event = ParayanEvent(
        id: '1',
        titleEn: 'Test',
        titleMr: 'Test',
        descriptionEn: 'Test',
        descriptionMr: 'Test',
        startDate: DateTime(2026, 5, 1), // Friday (शुक्रवार)
        endDate: DateTime(2026, 5, 1),
        type: ParayanType.oneDay,
        status: 'upcoming',
        reminderTimes: [],
        groupId: 'test',
        createdAt: DateTime.now(),
      );

      // शुक्रवार, १ मे, २०२६
      expect(event.getSmartDate('mr', includeTime: false), 'शुक्रवार, १ मे, २०२६');
    });

    test('returns multi-day date range with days of week (English)', () {
      final event = ParayanEvent(
        id: '1',
        titleEn: 'Test',
        titleMr: 'Test',
        descriptionEn: 'Test',
        descriptionMr: 'Test',
        startDate: DateTime(2026, 5, 1), // Friday
        endDate: DateTime(2026, 5, 3), // Sunday
        type: ParayanType.threeDay,
        status: 'upcoming',
        reminderTimes: [],
        groupId: 'test',
        createdAt: DateTime.now(),
      );

      expect(event.getSmartDate('en', includeTime: false), 'Friday, May 1 - Sunday, May 3, 2026');
    });

    test('returns multi-day date range with days of week (Marathi)', () {
      final event = ParayanEvent(
        id: '1',
        titleEn: 'Test',
        titleMr: 'Test',
        descriptionEn: 'Test',
        descriptionMr: 'Test',
        startDate: DateTime(2026, 5, 1), // Friday
        endDate: DateTime(2026, 5, 3), // Sunday
        type: ParayanType.threeDay,
        status: 'upcoming',
        reminderTimes: [],
        groupId: 'test',
        createdAt: DateTime.now(),
      );

      // शुक्रवार, १ मे - रविवार, ३ मे, २०२६
      expect(event.getSmartDate('mr', includeTime: false), 'शुक्रवार, १ मे - रविवार, ३ मे, २०२६');
    });
  });
}

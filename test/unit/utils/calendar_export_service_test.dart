import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/utils/calendar_export_service.dart';

void main() {
  group('CalendarExportService', () {
    test('generateEventsIcs should create valid VCALENDAR with events', () {
      final start = Timestamp.fromDate(DateTime(2024, 5, 1, 10, 0));
      final events = [
        Event(
          title_en: 'Test Event 1',
          title_mr: 'चाचणी',
          start_time: start,
          details_en: 'Location 1',
        ),
      ];

      final ics = CalendarExportService.generateEventsIcs(events, 'My Calendar');

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('X-WR-CALNAME:My Calendar'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('SUMMARY:Test Event 1'));
      expect(ics, contains('DESCRIPTION:Location 1'));
      expect(ics, contains('END:VEVENT'));
      expect(ics, contains('END:VCALENDAR'));
    });

    test('generateParayansIcs should create valid VCALENDAR for parayans', () {
      final events = [
        ParayanEvent(
          id: 'p1',
          titleEn: 'Gajanan Parayan',
          titleMr: 'पारायण',
          descriptionEn: 'Info',
          descriptionMr: 'माहिती',
          type: ParayanType.oneDay,
          startDate: DateTime(2024, 5, 1),
          endDate: DateTime(2024, 5, 1),
          status: 'upcoming',
          reminderTimes: [],
          createdAt: DateTime.now(),
          groupId: 'g1',
        ),
      ];

      final ics = CalendarExportService.generateParayansIcs(events, 'Parayan Cal');

      expect(ics, contains('X-WR-CALNAME:Parayan Cal'));
      expect(ics, contains('SUMMARY:1-Day Parayan: Gajanan Parayan'));
      expect(ics, contains('DTSTART;VALUE=DATE:20240501'));
      // DTEND should be next day for all-day events
      expect(ics, contains('DTEND;VALUE=DATE:20240502'));
    });

    test('ICS should escape special characters', () {
      final events = [
        Event(
          title_en: 'Escape; Me, Now\\',
          title_mr: '',
          start_time: Timestamp.now(),
        ),
      ];

      final ics = CalendarExportService.generateEventsIcs(events, 'Cal');
      expect(ics, contains('SUMMARY:Escape\\; Me\\, Now\\\\'));
    });
  });
}

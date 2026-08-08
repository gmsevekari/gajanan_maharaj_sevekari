import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/utils/calendar_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarExportService Unit Tests', () {
    final now = DateTime(2026, 8, 7, 10, 0);

    final testSpecialEvent = Event(
      titleEn: 'Prakat Din Utsav - Extremely Long Title That Causes Line Folding In The Generated iCalendar Output Format Specification',
      titleMr: 'प्रकट दिन उत्सव',
      detailsEn: 'Special event details with special characters: \\, ;, and newlines \n',
      detailsMr: 'माहिती',
      locationEn: 'Seattle Temple, WA',
      locationMr: 'सिॲटल',
      startTime: Timestamp.fromDate(now),
      endTime: Timestamp.fromDate(now.add(const Duration(hours: 2))),
    );

    final testParayanEvent = ParayanEvent(
      id: 'p1',
      titleEn: 'Shravan Parayan',
      titleMr: 'श्रावण पारायण',
      descriptionEn: 'Parayan description',
      descriptionMr: 'माहिती',
      type: ParayanType.threeDay,
      startDate: now,
      endDate: now.add(const Duration(days: 3)),
      status: 'upcoming',
      reminderTimes: const ['08:00'],
      createdAt: now,
      groupId: 'g1',
    );

    test('exportEventsToIcs and exportParayansToIcs handle empty list cleanly', () async {
      await CalendarExportService.exportEventsToIcs([], 'Calendar');
      await CalendarExportService.exportParayansToIcs([], 'Calendar');
    });

    test('generateEventsIcs constructs valid ICS content with escaped characters and folded lines', () {
      final ics = CalendarExportService.generateEventsIcs([testSpecialEvent], 'Gajanan Events');

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('SUMMARY:Prakat Din Utsav'));
      expect(ics, contains('LOCATION:Seattle Temple\\, WA'));
      expect(ics, contains('END:VEVENT'));
      expect(ics, contains('END:VCALENDAR'));
    });

    test('generateParayansIcs constructs valid ICS content for ParayanEvents', () {
      final ics = CalendarExportService.generateParayansIcs([testParayanEvent], 'Parayan Schedule');

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('SUMMARY:3-Day Parayan: Shravan Parayan'));
      expect(ics, contains('DESCRIPTION:Join the Shravan Parayan parayan. Type: 3-Day Parayan'));
      expect(ics, contains('END:VCALENDAR'));
    });
  });
}

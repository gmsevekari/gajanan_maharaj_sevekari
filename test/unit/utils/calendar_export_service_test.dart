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
      // Verify line folding: lines > 75 chars must be continued with CRLF+SPACE
      final lines = ics.split('\r\n');
      for (final line in lines) {
        // Continuation lines start with a space so skip them
        if (!line.startsWith(' ')) {
          expect(line.length, lessThanOrEqualTo(75));
        }
      }
    });

    test('generateEventsIcs handles event with null endTime (uses +1h fallback)', () {
      final eventNoEnd = Event(
        titleEn: 'No End Time Event',
        titleMr: 'शेवट नाही',
        detailsEn: 'Details',
        detailsMr: 'माहिती',
        locationEn: null,
        locationMr: null,
        startTime: Timestamp.fromDate(now),
        endTime: null, // null endTime → should default to startTime + 1 hour
      );
      final ics = CalendarExportService.generateEventsIcs([eventNoEnd], 'Test');
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('SUMMARY:No End Time Event'));
      // No LOCATION line since locationEn is null
      expect(ics, isNot(contains('LOCATION:')));
    });

    test('generateEventsIcs escapes backslash, semicolon, and newline chars', () {
      final eventWithSpecials = Event(
        titleEn: 'Event; with specials',
        titleMr: 'इव्हेंट',
        detailsEn: 'Has \\backslash and \nNewline and ;semicolon',
        detailsMr: 'माहिती',
        locationEn: 'Hall; B\\Wing',
        locationMr: 'हॉल',
        startTime: Timestamp.fromDate(now),
        endTime: Timestamp.fromDate(now.add(const Duration(hours: 1))),
      );
      final ics = CalendarExportService.generateEventsIcs([eventWithSpecials], 'Test');
      expect(ics, contains('SUMMARY:Event\\; with specials'));
      expect(ics, contains('LOCATION:Hall\\; B\\\\Wing'));
    });

    test('generateParayansIcs constructs valid ICS content for ParayanEvents', () {
      final ics = CalendarExportService.generateParayansIcs([testParayanEvent], 'Parayan Schedule');

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('SUMMARY:3-Day Parayan: Shravan Parayan'));
      expect(ics, contains('DESCRIPTION:Join the Shravan Parayan parayan. Type: 3-Day Parayan'));
      expect(ics, contains('END:VCALENDAR'));
    });

    test('generateParayansIcs handles one-day parayan type', () {
      final oneDayEvent = ParayanEvent(
        id: 'p2',
        titleEn: 'Single Day Parayan',
        titleMr: 'एकदिवसीय पारायण',
        descriptionEn: 'desc',
        descriptionMr: 'माहिती',
        type: ParayanType.oneDay,
        startDate: now,
        endDate: now,
        status: 'upcoming',
        reminderTimes: const [],
        createdAt: now,
        groupId: 'g1',
      );
      final ics = CalendarExportService.generateParayansIcs([oneDayEvent], 'Test');
      expect(ics, contains('SUMMARY:1-Day Parayan: Single Day Parayan'));
    });

    test('generateParayansIcs handles guruPushya parayan type', () {
      final guruPushyaEvent = ParayanEvent(
        id: 'p3',
        titleEn: 'GuruPushya Parayan',
        titleMr: 'गुरुपुष्य पारायण',
        descriptionEn: 'desc',
        descriptionMr: 'माहिती',
        type: ParayanType.guruPushya,
        startDate: now,
        endDate: now,
        status: 'upcoming',
        reminderTimes: const [],
        createdAt: now,
        groupId: 'g1',
      );
      final ics = CalendarExportService.generateParayansIcs([guruPushyaEvent], 'Test');
      expect(ics, contains('SUMMARY:GuruPushya Parayan: GuruPushya Parayan'));
    });

    test('generateEventsIcs handles very long title triggering multi-iteration fold (>149 chars)', () {
      // The _fold while loop (lines 138-140) only fires when remaining > 74 chars
      // after the first 75-char chunk. Need original line > 75+74 = 149 chars.
      // SUMMARY: prefix adds 8 chars, so title needs to be > 141 chars.
      final longTitle = 'A' * 150; // 150 A's → SUMMARY: + 150 A's = 158 chars, needs multi-fold
      final eventWithLongTitle = Event(
        titleEn: longTitle,
        titleMr: 'लांब शीर्षक',
        detailsEn: null,
        detailsMr: null,
        locationEn: null,
        locationMr: null,
        startTime: Timestamp.fromDate(now),
        endTime: Timestamp.fromDate(now.add(const Duration(hours: 1))),
      );
      final ics = CalendarExportService.generateEventsIcs([eventWithLongTitle], 'Test');
      // Verify content is present (folded across multiple lines)
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('END:VEVENT'));
      // All lines (non-continuation) must be <= 75 chars
      final lines = ics.split('\r\n');
      for (final line in lines) {
        if (!line.startsWith(' ')) {
          expect(line.length, lessThanOrEqualTo(75));
        }
      }
    });

    test('generateEventsIcs escapes carriage-return newline sequences', () {
      final eventWithCRLF = Event(
        titleEn: 'Event Title',
        titleMr: 'शीर्षक',
        detailsEn: 'Line1\r\nLine2\rLine3',
        detailsMr: 'माहिती',
        locationEn: null,
        locationMr: null,
        startTime: Timestamp.fromDate(now),
        endTime: Timestamp.fromDate(now.add(const Duration(hours: 1))),
      );
      final ics = CalendarExportService.generateEventsIcs([eventWithCRLF], 'Test');
      // \r\n, \r should be escaped to \n in ICS
      expect(ics, contains('DESCRIPTION:Line1\\nLine2\\nLine3'));
    });
  });
}

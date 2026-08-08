import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('mr');
    await initializeDateFormatting('en');
  });

  group('DateTimeUtils Tests', () {
    final date = DateTime(2026, 7, 21, 14, 30);

    test('formatDateLong formats correctly for en and mr', () {
      final enStr = formatDateLong(date, 'en');
      final mrStr = formatDateLong(date, 'mr');

      expect(enStr, contains('July 21, 2026'));
      expect(mrStr, contains('२१ जुलै, २०२६'));
    });

    test('formatDateWithDay formats with day name', () {
      final enStr = formatDateWithDay(date, 'en');
      final mrStr = formatDateWithDay(date, 'mr');

      expect(enStr, contains('Tuesday, July 21, 2026'));
      expect(mrStr, contains('२१ जुलै, २०२६'));
    });

    test('formatDateShort and formatDateShortWithDay format short dates', () {
      final enShort = formatDateShort(date, 'en');
      final mrShort = formatDateShort(date, 'mr');
      expect(enShort, equals('July 21'));
      expect(mrShort, equals('२१ जुलै'));

      final enShortDay = formatDateShortWithDay(date, 'en');
      final mrShortDay = formatDateShortWithDay(date, 'mr');
      expect(enShortDay, contains('Tuesday, July 21'));
      expect(mrShortDay, contains('२१ जुलै'));
    });

    test('formatTimeLocalized formats time across all periods for mr and en', () {
      // Morning (5-12)
      final morning = DateTime(2026, 7, 21, 8, 15);
      expect(formatTimeLocalized(morning, 'mr'), contains('स. ८:१५'));
      expect(formatTimeLocalized(morning, 'en'), equals('8:15 am'));

      // Afternoon (12-17)
      final afternoon = DateTime(2026, 7, 21, 14, 30);
      expect(formatTimeLocalized(afternoon, 'mr'), contains('दु. २:३०'));
      expect(formatTimeLocalized(afternoon, 'en'), equals('2:30 pm'));

      // Evening (17-20)
      final evening = DateTime(2026, 7, 21, 18, 45);
      expect(formatTimeLocalized(evening, 'mr'), contains('सं. ६:४५'));

      // Night (20-5)
      final night = DateTime(2026, 7, 21, 22, 10);
      expect(formatTimeLocalized(night, 'mr'), contains('रा. १०:१०'));
    });

    test('formatTimeDetailed formats time with detailed Marathi prefixes', () {
      final morning = DateTime(2026, 7, 21, 8, 15);
      expect(formatTimeDetailed(morning, 'mr'), contains('सकाळी ८:१५'));

      final afternoon = DateTime(2026, 7, 21, 14, 30);
      expect(formatTimeDetailed(afternoon, 'mr'), contains('दुपारी २:३०'));

      final evening = DateTime(2026, 7, 21, 18, 45);
      expect(formatTimeDetailed(evening, 'mr'), contains('सायंकाळी ६:४५'));

      final night = DateTime(2026, 7, 21, 22, 10);
      expect(formatTimeDetailed(night, 'mr'), contains('रात्री १०:१०'));

      expect(formatTimeDetailed(morning, 'en'), equals('8:15 am'));
    });

    test('formatDateMedium supports time inclusion and month year formatting', () {
      final mediumNoTime = formatDateMedium(date, 'en');
      expect(mediumNoTime, equals('Jul 21, 2026'));

      final mediumWithTime = formatDateMedium(date, 'en', includeTime: true);
      expect(mediumWithTime, contains('Jul 21, 2026 - 02:30 PM'));

      final monthYearMr = formatMonthYear(date, 'mr');
      expect(monthYearMr, contains('जुलै २०२६'));
    });

    test('convertTextTimings dynamically converts schedule timings with offsets', () {
      expect(convertTextTimings('', date, 'en'), equals(''));
      expect(convertTextTimings('No times here', date, 'en'), equals('No times here'));

      // Text with Marathi morning time
      final textMr = 'स. १०:३० आरती';
      final convertedMr = convertTextTimings(textMr, DateTime(2026, 7, 21, 10, 30), 'mr');
      expect(convertedMr, contains('स. १०:३०'));

      // Text with English PM time
      final textEn = '10:30 am Aarti, 2:00 pm Mahaprasad';
      final convertedEn = convertTextTimings(textEn, DateTime(2026, 7, 21, 10, 30), 'en');
      expect(convertedEn, contains('10:30 am'));

      // Sequential time wrap test
      final textSequential = '11:30 am Stotra, 1:00 PM Pooja';
      final convertedSeq = convertTextTimings(textSequential, DateTime(2026, 7, 21, 11, 30), 'en');
      expect(convertedSeq, contains('1:00 pm'));
    });

    test('isPacificDST accurately handles March/November Sunday boundaries', () {
      // Winter / Non-DST months
      expect(isPacificDST(DateTime(2026, 1, 15)), isFalse);
      expect(isPacificDST(DateTime(2026, 12, 15)), isFalse);

      // Summer / DST months
      expect(isPacificDST(DateTime(2026, 6, 15)), isTrue);

      // March boundary (2nd Sunday of March 2026 is March 8)
      expect(isPacificDST(DateTime(2026, 3, 1)), isFalse);
      expect(isPacificDST(DateTime(2026, 3, 8, 1, 59)), isFalse);
      expect(isPacificDST(DateTime(2026, 3, 8, 2, 00)), isTrue);
      expect(isPacificDST(DateTime(2026, 3, 15)), isTrue);

      // November boundary (1st Sunday of Nov 2026 is Nov 1)
      expect(isPacificDST(DateTime(2026, 11, 1, 1, 59)), isTrue);
      expect(isPacificDST(DateTime(2026, 11, 1, 2, 00)), isFalse);
      expect(isPacificDST(DateTime(2026, 11, 15)), isFalse);
    });

    test('formatDateShortWithEventTimezone formats correctly for Asia/Kolkata and America/Los_Angeles', () {
      final utcDate = DateTime.utc(2026, 7, 21, 10, 0);

      final indiaDate = formatDateShortWithEventTimezone(utcDate, 'Asia/Kolkata', 'en');
      expect(indiaDate, equals('July 21'));

      final usDate = formatDateShortWithEventTimezone(utcDate, 'America/Los_Angeles', 'en');
      expect(usDate, equals('July 21'));

      final indiaDateMr = formatDateShortWithEventTimezone(utcDate, 'Asia/Kolkata', 'mr');
      expect(indiaDateMr, equals('२१ जुलै'));
    });
  });
}

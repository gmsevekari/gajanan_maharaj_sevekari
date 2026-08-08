import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/parayan/utils/parayan_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('mr');
    await initializeDateFormatting('en');
  });

  group('ParayanEventFormatting Extensions Unit Tests', () {
    final start = DateTime(2026, 7, 21, 6, 0);
    final endSameDay = DateTime(2026, 7, 21, 18, 0);
    final endMultiDay = DateTime(2026, 7, 23, 18, 0);

    final oneDayEvent = ParayanEvent(
      id: 'e1',
      titleEn: 'One Day Parayan',
      titleMr: 'एक दिवशीय पारायण',
      descriptionEn: 'Description En',
      descriptionMr: 'माहिती म्',
      startDate: start,
      endDate: endSameDay,
      type: ParayanType.oneDay,
      status: 'enrolling',
      reminderTimes: const ['08:00', '20:00'],
      createdAt: start,
      groupId: 'g1',
    );

    final threeDayEvent = ParayanEvent(
      id: 'e2',
      titleEn: 'Three Day Parayan',
      titleMr: 'त्रिदिवसीय पारायण',
      descriptionEn: 'Description En',
      descriptionMr: 'माहिती म्',
      startDate: start,
      endDate: endMultiDay,
      type: ParayanType.threeDay,
      status: 'upcoming',
      reminderTimes: const ['08:00', '20:00'],
      createdAt: start,
      groupId: 'g1',
    );

    test('getSmartDate handles same day and multi day events with time formatting', () {
      final oneDayStr = oneDayEvent.getSmartDate('en');
      expect(oneDayStr, contains('Tuesday, July 21, 2026'));

      final threeDayStr = threeDayEvent.getSmartDate('en');
      expect(threeDayStr, contains('Tuesday, July 21'));
      expect(threeDayStr, contains('Thursday, July 23, 2026'));
      expect(threeDayStr, contains('6:00 am - 6:00 pm'));
    });

    testWidgets('getDescriptiveStatus returns correct localization string per status', (WidgetTester tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox();
          }),
        ),
      );

      // Testing statuses for standard wording
      expect(oneDayEvent.getDescriptiveStatus(l10n, 'en'), contains('July 21, 2026'));

      final ongoingEvent = ParayanEvent(
        id: 'e1',
        titleEn: 'One Day Parayan',
        titleMr: 'एक दिवशीय पारायण',
        descriptionEn: 'Description En',
        descriptionMr: 'माहिती म्',
        startDate: start,
        endDate: endSameDay,
        type: ParayanType.oneDay,
        status: 'ongoing',
        reminderTimes: const ['08:00'],
        createdAt: start,
        groupId: 'g1',
      );
      expect(ongoingEvent.getDescriptiveStatus(l10n, 'en'), equals(l10n.statusOngoingDesc));

      final completedEvent = ParayanEvent(
        id: 'e1',
        titleEn: 'One Day Parayan',
        titleMr: 'एक दिवशीय पारायण',
        descriptionEn: 'Description En',
        descriptionMr: 'माहिती म्',
        startDate: start,
        endDate: endSameDay,
        type: ParayanType.oneDay,
        status: 'completed',
        reminderTimes: const ['08:00'],
        createdAt: start,
        groupId: 'g1',
      );
      expect(completedEvent.getDescriptiveStatus(l10n, 'en'), equals(l10n.statusCompletedDesc));

      // Preallocated wording
      expect(
        threeDayEvent.getDescriptiveStatus(l10n, 'en', usePreallocatedWording: true),
        contains('July 21, 2026'),
      );
    });
  });
}

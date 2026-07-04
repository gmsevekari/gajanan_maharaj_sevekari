import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:gajanan_maharaj_sevekari/vaari/widgets/vaari_participants_table.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';

class MockVaariService extends Mock implements VaariService {}

void main() {
  late MockVaariService mockService;

  setUp(() {
    mockService = MockVaariService();
  });

  Widget createWidget({Locale? locale}) {
    return Provider<VaariService>.value(
      value: mockService,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale ?? const Locale('en'),
        home: Scaffold(
          body: const VaariParticipantsTable(
            eventId: 'vaari_1',
            distanceUnitLabel: 'miles',
          ),
        ),
      ),
    );
  }

  group('VaariParticipantsTable Widget Tests', () {
    testWidgets('renders header row with distance unit in brackets', (
      tester,
    ) async {
      when(
        () => mockService.getAllParticipants('vaari_1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('Distance (miles)'), findsOneWidget);
    });

    testWidgets('renders empty state when there are no participants', (
      tester,
    ) async {
      when(
        () => mockService.getAllParticipants('vaari_1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No participants yet'), findsOneWidget);
    });

    testWidgets('renders a row per participant with formatted values', (
      tester,
    ) async {
      when(() => mockService.getAllParticipants('vaari_1')).thenAnswer(
        (_) => Stream.value([
          VaariParticipant(
            memberName: 'Abhishek',
            deviceId: 'device_1',
            phone: '123',
            joinedAt: DateTime.now(),
            totalSteps: 15000,
            totalDistance: 7.5,
          ),
          VaariParticipant(
            memberName: 'Rahul',
            deviceId: 'device_2',
            phone: '456',
            joinedAt: DateTime.now(),
            totalSteps: 3000,
            totalDistance: 1.5,
          ),
        ]),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Abhishek'), findsOneWidget);
      expect(find.text('15,000'), findsOneWidget);
      expect(find.text('7.5'), findsOneWidget);
      expect(find.text('Rahul'), findsOneWidget);
      expect(find.text('3,000'), findsOneWidget);
      expect(find.text('1.5'), findsOneWidget);
    });

    testWidgets('formats values using Marathi numerals in Marathi locale', (
      tester,
    ) async {
      when(() => mockService.getAllParticipants('vaari_1')).thenAnswer(
        (_) => Stream.value([
          VaariParticipant(
            memberName: 'Abhishek',
            deviceId: 'device_1',
            phone: '123',
            joinedAt: DateTime.now(),
            totalSteps: 15000,
            totalDistance: 7.5,
          ),
        ]),
      );

      await tester.pumpWidget(createWidget(locale: const Locale('mr')));
      await tester.pumpAndSettle();

      expect(find.text('१५,०००'), findsOneWidget);
      expect(find.text('७.५'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:gajanan_maharaj_sevekari/vaari/widgets/add_steps_dialog.dart';

class MockVaariService extends Mock implements VaariService {}

void main() {
  late MockVaariService mockService;

  setUp(() {
    mockService = MockVaariService();
    when(
      () => mockService.submitSteps(
        eventId: any(named: 'eventId'),
        deviceId: any(named: 'deviceId'),
        memberName: any(named: 'memberName'),
        stepsToSubmit: any(named: 'stepsToSubmit'),
        distanceToSubmit: any(named: 'distanceToSubmit'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget createWidget({String distanceUnit = 'mi'}) {
    return Provider<VaariService>.value(
      value: mockService,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AddStepsDialog(
                  eventId: 'event1',
                  deviceId: 'device1',
                  memberName: 'Test User',
                  distanceUnit: distanceUnit,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('AddStepsDialog Tests', () {
    testWidgets('shows a confirmation dialog with the entered steps and '
        'estimated distance before submitting', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Steps'), '2000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Submission'), findsOneWidget);
      expect(find.text('Steps: 2,000'), findsOneWidget);
      expect(find.text('Distance: 1.00 mi'), findsOneWidget);
      expect(
        find.text('Are you sure you want to submit these details?'),
        findsOneWidget,
      );

      // Not yet submitted — waiting on confirmation.
      verifyNever(
        () => mockService.submitSteps(
          eventId: any(named: 'eventId'),
          deviceId: any(named: 'deviceId'),
          memberName: any(named: 'memberName'),
          stepsToSubmit: any(named: 'stepsToSubmit'),
          distanceToSubmit: any(named: 'distanceToSubmit'),
        ),
      );
    });

    testWidgets('shows the distance entered directly when in distance mode', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(distanceUnit: 'km'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Distance'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '3.5');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Submission'), findsOneWidget);
      expect(find.text('Distance: 3.50 km'), findsOneWidget);
    });

    testWidgets('cancelling the confirmation does not submit', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Steps'), '2000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'No'));
      await tester.pumpAndSettle();

      // Confirmation dialog is gone, original dialog is still open.
      expect(find.text('Confirm Submission'), findsNothing);
      expect(find.byType(AddStepsDialog), findsOneWidget);
      verifyNever(
        () => mockService.submitSteps(
          eventId: any(named: 'eventId'),
          deviceId: any(named: 'deviceId'),
          memberName: any(named: 'memberName'),
          stepsToSubmit: any(named: 'stepsToSubmit'),
          distanceToSubmit: any(named: 'distanceToSubmit'),
        ),
      );
    });

    testWidgets('confirming submits with the entered steps', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Steps'), '2000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Yes'));
      await tester.pumpAndSettle();

      verify(
        () => mockService.submitSteps(
          eventId: 'event1',
          deviceId: 'device1',
          memberName: 'Test User',
          stepsToSubmit: 2000,
          distanceToSubmit: null,
        ),
      ).called(1);
    });
  });
}

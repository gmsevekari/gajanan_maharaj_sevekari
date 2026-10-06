import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/claim_entries_result.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/claim_my_signup_dialog.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignupService extends Mock implements SignupService {}

void main() {
  late _MockSignupService service;
  bool? dialogResult;

  setUp(() {
    service = _MockSignupService();
    dialogResult = null;
  });

  void stubClaim(Future<ClaimEntriesResult> Function() answer) {
    when(
      () => service.claimMyEntries(
        signupId: any(named: 'signupId'),
        phone: any(named: 'phone'),
        deviceId: any(named: 'deviceId'),
        joinCode: any(named: 'joinCode'),
      ),
    ).thenAnswer((_) => answer());
  }

  Future<void> open(
    WidgetTester tester, {
    bool requiresJoinCode = false,
    String? defaultCountryCode,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                dialogResult = await showDialog<bool>(
                  context: context,
                  builder: (_) => ClaimMySignupDialog(
                    signupId: 'signup_1',
                    deviceId: 'device_a',
                    requiresJoinCode: requiresJoinCode,
                    signupService: service,
                    defaultCountryCode: defaultCountryCode,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> enterPhone(WidgetTester tester, String number) =>
      tester.enterText(find.byKey(const Key('claimMyPhoneField')), number);

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
  }

  String codeText(WidgetTester tester) => tester
      .widget<TextFormField>(find.byKey(const Key('claimMyCountryCodeField')))
      .controller!
      .text;

  group('layout', () {
    testWidgets('asks for a phone number, with a hint, and nothing else', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Claim My Sign Up'), findsOneWidget);
      expect(
        find.text('Enter the phone number you signed up with.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('claimMyPhoneField')), findsOneWidget);
      expect(find.byKey(const Key('claimMyJoinCodeField')), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('starts with +1 unless given a country code', (tester) async {
      await open(tester);
      expect(codeText(tester), '+1');
    });

    testWidgets('starts with the given country code', (tester) async {
      await open(tester, defaultCountryCode: '+91');
      expect(codeText(tester), '+91');
    });

    testWidgets('asks for the join code only when the sign-up needs one', (
      tester,
    ) async {
      await open(tester, requiresJoinCode: true);

      expect(find.byKey(const Key('claimMyJoinCodeField')), findsOneWidget);
    });

    testWidgets('fits a small screen with the keyboard up', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.reset);

      await open(tester, requiresJoinCode: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a 360px screen at large text, with an error shown', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      stubClaim(
        () async => const ClaimEntriesResult(ClaimEntriesStatus.alreadyClaimed),
      );

      await open(tester, requiresJoinCode: true);
      await enterPhone(tester, '4255551234');
      await tester.enterText(
        find.byKey(const Key('claimMyJoinCodeField')),
        'ABC123',
      );
      await submit(tester);

      expect(tester.takeException(), isNull);
      expect(
        find.text('This entry is already claimed by someone else.'),
        findsOneWidget,
      );
    });
  });

  group('validation', () {
    testWidgets('needs a phone number', (tester) async {
      await open(tester);

      await submit(tester);

      expect(find.text('Phone number is required'), findsOneWidget);
      verifyNever(
        () => service.claimMyEntries(
          signupId: any(named: 'signupId'),
          phone: any(named: 'phone'),
          deviceId: any(named: 'deviceId'),
          joinCode: any(named: 'joinCode'),
        ),
      );
    });

    testWidgets('rejects a number that is too short', (tester) async {
      await open(tester);

      await enterPhone(tester, '123');
      await submit(tester);

      expect(find.text('Please enter a valid phone number'), findsOneWidget);
    });

    testWidgets('needs the join code when the sign-up requires one', (
      tester,
    ) async {
      await open(tester, requiresJoinCode: true);

      await enterPhone(tester, '4255551234');
      await submit(tester);

      expect(find.text('Enter 6-character code'), findsWidgets);
      verifyNever(
        () => service.claimMyEntries(
          signupId: any(named: 'signupId'),
          phone: any(named: 'phone'),
          deviceId: any(named: 'deviceId'),
          joinCode: any(named: 'joinCode'),
        ),
      );
    });
  });

  group('claiming', () {
    testWidgets('sends the full phone and closes with true on success', (
      tester,
    ) async {
      stubClaim(
        () async =>
            const ClaimEntriesResult(ClaimEntriesStatus.success, count: 1),
      );
      await open(tester);

      await enterPhone(tester, '425 555 1234');
      await submit(tester);

      verify(
        () => service.claimMyEntries(
          signupId: 'signup_1',
          phone: '+1425 555 1234',
          deviceId: 'device_a',
          joinCode: null,
        ),
      ).called(1);
      expect(dialogResult, isTrue);
      expect(find.text('Claim My Sign Up'), findsNothing);
    });

    testWidgets('sends the join code in upper case when required', (
      tester,
    ) async {
      stubClaim(
        () async =>
            const ClaimEntriesResult(ClaimEntriesStatus.success, count: 1),
      );
      await open(tester, requiresJoinCode: true, defaultCountryCode: '+91');

      await enterPhone(tester, '9876543210');
      await tester.enterText(
        find.byKey(const Key('claimMyJoinCodeField')),
        ' ab12cd ',
      );
      await submit(tester);

      verify(
        () => service.claimMyEntries(
          signupId: 'signup_1',
          phone: '+919876543210',
          deviceId: 'device_a',
          joinCode: 'AB12CD',
        ),
      ).called(1);
    });

    testWidgets('does not send a join code the sign-up does not need', (
      tester,
    ) async {
      stubClaim(
        () async =>
            const ClaimEntriesResult(ClaimEntriesStatus.success, count: 1),
      );
      await open(tester);

      await enterPhone(tester, '4255551234');
      await submit(tester);

      verify(
        () => service.claimMyEntries(
          signupId: any(named: 'signupId'),
          phone: any(named: 'phone'),
          deviceId: any(named: 'deviceId'),
          joinCode: null,
        ),
      ).called(1);
    });

    for (final (status, message) in [
      (ClaimEntriesStatus.notFound, 'No sign up found for this phone number.'),
      (
        ClaimEntriesStatus.alreadyClaimed,
        'This entry is already claimed by someone else.',
      ),
      (ClaimEntriesStatus.invalidJoinCode, 'Invalid Join Code!'),
    ]) {
      testWidgets('shows "$message" and stays open for $status', (
        tester,
      ) async {
        stubClaim(() async => ClaimEntriesResult(status));
        await open(tester, requiresJoinCode: true);

        await enterPhone(tester, '4255551234');
        await tester.enterText(
          find.byKey(const Key('claimMyJoinCodeField')),
          'ABC123',
        );
        await submit(tester);

        expect(find.text(message), findsOneWidget);
        expect(find.text('Claim My Sign Up'), findsOneWidget);
        expect(dialogResult, isNull);
        // What was typed is kept, and Submit works again.
        expect(find.text('4255551234'), findsOneWidget);
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Submit'),
              )
              .onPressed,
          isNotNull,
        );
      });
    }

    testWidgets('clears a refusal when submitting again', (tester) async {
      var calls = 0;
      stubClaim(() async {
        calls++;
        return calls == 1
            ? const ClaimEntriesResult(ClaimEntriesStatus.notFound)
            : const ClaimEntriesResult(ClaimEntriesStatus.success, count: 1);
      });
      await open(tester);
      await enterPhone(tester, '4255551234');
      await submit(tester);
      expect(
        find.text('No sign up found for this phone number.'),
        findsOneWidget,
      );

      await submit(tester);

      expect(dialogResult, isTrue);
    });

    testWidgets('hides an earlier refusal while the next attempt is under '
        'way', (tester) async {
      final second = Completer<ClaimEntriesResult>();
      var calls = 0;
      stubClaim(() {
        calls++;
        return calls == 1
            ? Future.value(
                const ClaimEntriesResult(ClaimEntriesStatus.notFound),
              )
            : second.future;
      });
      await open(tester);
      await enterPhone(tester, '4255551234');
      await submit(tester);
      expect(
        find.text('No sign up found for this phone number.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(
        find.text('No sign up found for this phone number.'),
        findsNothing,
      );
      second.complete(
        const ClaimEntriesResult(ClaimEntriesStatus.success, count: 1),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('shows a plain message, not the exception, when the call '
        'fails', (tester) async {
      stubClaim(() async => throw Exception('internal: secret detail'));
      await open(tester);

      await enterPhone(tester, '4255551234');
      await submit(tester);

      expect(
        find.text("Couldn't claim your sign up. Please try again."),
        findsOneWidget,
      );
      expect(find.textContaining('secret'), findsNothing);
      expect(find.text('Claim My Sign Up'), findsOneWidget);
    });

    testWidgets('disables the buttons and shows progress while claiming', (
      tester,
    ) async {
      final done = Completer<ClaimEntriesResult>();
      stubClaim(() => done.future);
      await open(tester);

      await enterPhone(tester, '4255551234');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .last
            .onPressed,
        isNull,
      );

      done.complete(
        const ClaimEntriesResult(ClaimEntriesStatus.success, count: 1),
      );
      await tester.pumpAndSettle();
      expect(dialogResult, isTrue);
    });

    testWidgets('cannot be dismissed while claiming, but can afterwards', (
      tester,
    ) async {
      final done = Completer<ClaimEntriesResult>();
      stubClaim(() => done.future);
      await open(tester);
      await enterPhone(tester, '4255551234');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      // Tapping outside the dialog and the back button do nothing.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Claim My Sign Up'), findsOneWidget);

      done.complete(const ClaimEntriesResult(ClaimEntriesStatus.notFound));
      await tester.pumpAndSettle();
      expect(find.text('Claim My Sign Up'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Claim My Sign Up'), findsNothing);
    });

    testWidgets('Cancel closes without claiming', (tester) async {
      await open(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Claim My Sign Up'), findsNothing);
      expect(dialogResult, isNull);
      verifyNever(
        () => service.claimMyEntries(
          signupId: any(named: 'signupId'),
          phone: any(named: 'phone'),
          deviceId: any(named: 'deviceId'),
          joinCode: any(named: 'joinCode'),
        ),
      );
    });
  });
}

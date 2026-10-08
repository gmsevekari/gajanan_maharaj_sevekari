import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/notifications/signup_reminder_permission_hint.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late int asked;
  late int openedSettings;
  late AuthorizationStatus status;

  SignupReminderPermissionHint hint({Object? statusError}) =>
      SignupReminderPermissionHint(
        authorizationStatus: () async {
          if (statusError != null) throw statusError;
          return status;
        },
        requestPermission: () async => asked++,
        openSettings: () async => openedSettings++,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    asked = 0;
    openedSettings = 0;
    status = AuthorizationStatus.denied;
  });

  Future<void> pumpHost(
    WidgetTester tester,
    SignupReminderPermissionHint hint, {
    Locale locale = const Locale('en'),
    AppLocalizations? l10n,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => hint.showIfNeeded(
                  context,
                  l10n ?? AppLocalizations.of(context)!,
                ),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> run(WidgetTester tester) async {
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
  }

  const message =
      'Turn on notifications to get a reminder before your '
      'sign-up.';

  testWidgets('offers to open settings when notifications are blocked', (
    tester,
  ) async {
    await pumpHost(tester, hint());

    await run(tester);

    expect(find.text(message), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(openedSettings, 1);
    expect(asked, 0);
  });

  testWidgets('stays up long enough to read and tap', (tester) async {
    await pumpHost(tester, hint());

    await run(tester);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.duration, const Duration(seconds: 8));
  });

  testWidgets('offers to allow them when they were never asked about', (
    tester,
  ) async {
    status = AuthorizationStatus.notDetermined;
    await pumpHost(tester, hint());

    await run(tester);

    expect(find.text(message), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(openedSettings, 0);
  });

  for (final allowed in [
    AuthorizationStatus.authorized,
    AuthorizationStatus.provisional,
  ]) {
    testWidgets('says nothing when notifications are $allowed', (tester) async {
      status = allowed;
      await pumpHost(tester, hint());

      await run(tester);

      expect(find.text(message), findsNothing);
    });
  }

  testWidgets('only ever says it once', (tester) async {
    await pumpHost(tester, hint());

    await run(tester);
    expect(find.text(message), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.text('Go'))).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await run(tester);

    expect(find.text(message), findsNothing);
  });

  testWidgets('does not use up its one time when nothing needed saying', (
    tester,
  ) async {
    status = AuthorizationStatus.authorized;
    await pumpHost(tester, hint());
    await run(tester);
    status = AuthorizationStatus.denied; // they switch them off later

    await run(tester);

    expect(find.text(message), findsOneWidget);
  });

  testWidgets('stays quiet when the devotee switched reminders off', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'signup_reminders_pref': false});
    await pumpHost(tester, hint());

    await run(tester);

    expect(find.text(message), findsNothing);
  });

  testWidgets('stays quiet when the status cannot be read', (tester) async {
    await pumpHost(tester, hint(statusError: Exception('no firebase')));

    await run(tester);

    expect(find.text(message), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('is worded with the strings it is given, not the app language', (
    tester,
  ) async {
    // The sign-up screens are English-only whatever the app language is.
    await pumpHost(
      tester,
      hint(),
      locale: const Locale('mr'),
      l10n: lookupAppLocalizations(const Locale('en')),
    );

    await run(tester);

    expect(find.text(message), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('can be worded in another language when given those strings', (
    tester,
  ) async {
    await pumpHost(
      tester,
      hint(),
      l10n: lookupAppLocalizations(const Locale('mr')),
    );

    await run(tester);

    expect(
      find.text('साइन अपची आठवण मिळण्यासाठी नोटिफिकेशन्स सुरू करा.'),
      findsOneWidget,
    );
    expect(find.text('सेटिंग्ज उघडा'), findsOneWidget);
  });

  testWidgets('a request that fails does not break the screen', (tester) async {
    status = AuthorizationStatus.notDetermined;
    await pumpHost(
      tester,
      SignupReminderPermissionHint(
        authorizationStatus: () async => status,
        requestPermission: () async => throw Exception('refused'),
        openSettings: () async {},
      ),
    );
    await run(tester);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

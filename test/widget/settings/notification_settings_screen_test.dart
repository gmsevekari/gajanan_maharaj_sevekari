import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:gajanan_maharaj_sevekari/notifications/signup_reminder_subscriptions.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/notification_settings_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockReminders extends Mock implements SignupReminderSubscriptions {}

void main() {
  late _MockReminders reminders;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    reminders = _MockReminders();
    when(() => reminders.setEnabled(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    bool authorized = true,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => FestivalProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationSettingsScreen(
            signupReminders: reminders,
            isAuthorized: () async => authorized,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder signupSwitch() =>
      find.widgetWithText(SwitchListTile, 'Sign-up Reminders');

  testWidgets('has a Sign-up Reminders switch, on to begin with', (
    tester,
  ) async {
    await pump(tester);

    expect(signupSwitch(), findsOneWidget);
    expect(tester.widget<SwitchListTile>(signupSwitch()).value, isTrue);
    expect(
      find.text(
        'A reminder 1 day and 1 hour before each sign-up slot you have signed '
        'up for',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the switch off if the devotee turned it off', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      NotificationConstants.signupRemindersPrefKey: false,
    });
    await pump(tester);

    expect(tester.widget<SwitchListTile>(signupSwitch()).value, isFalse);
  });

  testWidgets('switching it off unsubscribes the device', (tester) async {
    await pump(tester);

    await tester.tap(signupSwitch());
    await tester.pumpAndSettle();

    verify(() => reminders.setEnabled(false)).called(1);
    expect(tester.widget<SwitchListTile>(signupSwitch()).value, isFalse);
  });

  testWidgets('switching it back on subscribes the device again', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      NotificationConstants.signupRemindersPrefKey: false,
    });
    await pump(tester);

    await tester.tap(signupSwitch());
    await tester.pumpAndSettle();

    verify(() => reminders.setEnabled(true)).called(1);
    expect(tester.widget<SwitchListTile>(signupSwitch()).value, isTrue);
  });

  testWidgets('is a separate switch from the parayan one', (tester) async {
    await pump(tester);

    await tester.tap(signupSwitch());
    await tester.pumpAndSettle();

    final parayan = find.widgetWithText(SwitchListTile, 'Parayan Reminders');
    expect(tester.widget<SwitchListTile>(parayan).value, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(NotificationConstants.parayanRemindersPrefKey),
      isNull,
    );
  });

  testWidgets('cannot be changed while notifications are blocked', (
    tester,
  ) async {
    await pump(tester, authorized: false);

    expect(tester.widget<SwitchListTile>(signupSwitch()).onChanged, isNull);
    expect(tester.widget<SwitchListTile>(signupSwitch()).value, isFalse);
  });

  testWidgets('remembers the choice even if changing the subscriptions fails', (
    tester,
  ) async {
    when(
      () => reminders.setEnabled(any()),
    ).thenAnswer((_) async => throw Exception('offline'));
    await pump(tester);

    await tester.tap(signupSwitch());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.widget<SwitchListTile>(signupSwitch()).value, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(NotificationConstants.signupRemindersPrefKey),
      isFalse,
    );
  });

  testWidgets('remembers the choice at once, without waiting for the '
      'subscriptions', (tester) async {
    // A start-up sync can hold the subscription changes up for a while.
    when(
      () => reminders.setEnabled(any()),
    ).thenAnswer((_) => Completer<void>().future);
    await pump(tester);

    await tester.tap(signupSwitch());
    await tester.pump();
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(NotificationConstants.signupRemindersPrefKey),
      isFalse,
    );
  });

  testWidgets('is labelled in the app language', (tester) async {
    await pump(tester, locale: const Locale('mr'));

    expect(find.text('साइन अप रिमाइंडर'), findsOneWidget);
  });
}

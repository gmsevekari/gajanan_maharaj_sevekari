import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_mobile_app_notice.dart';

void main() {
  Widget wrap(Widget child, {Locale locale = const Locale('en')}) =>
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('says to use the mobile app, with an info icon', (tester) async {
    await tester.pumpWidget(wrap(const SignupMobileAppNotice()));

    expect(find.text('Please use the mobile app to sign up'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('wraps long text at 320px and large text without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      wrap(
        const Padding(
          padding: EdgeInsets.all(16),
          child: SignupMobileAppNotice(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'is worded in the app language when it is not forced to English',
    (tester) async {
      await tester.pumpWidget(
        wrap(const SignupMobileAppNotice(), locale: const Locale('mr')),
      );

      expect(
        find.text('साइन अप करण्यासाठी कृपया मोबाईल ॲप वापरा'),
        findsOneWidget,
      );
    },
  );
}

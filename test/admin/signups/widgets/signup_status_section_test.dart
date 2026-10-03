import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_status_section.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('starts locked, ignoring taps on the status segments', (
    tester,
  ) async {
    SignupStatus? changedTo;

    await tester.pumpWidget(
      wrap(
        SignupStatusSection(
          currentStatus: SignupStatus.draft,
          onStatusChanged: (status) => changedTo = status,
        ),
      ),
    );

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    await tester.tap(find.text('Published'));
    await tester.pumpAndSettle();

    expect(changedTo, isNull);
  });

  testWidgets('unlocking allows selecting a different status', (tester) async {
    SignupStatus? changedTo;

    await tester.pumpWidget(
      wrap(
        SignupStatusSection(
          currentStatus: SignupStatus.draft,
          onStatusChanged: (status) => changedTo = status,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.lock_outline));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_open), findsOneWidget);

    await tester.tap(find.text('Published'));
    await tester.pumpAndSettle();

    expect(changedTo, SignupStatus.published);
  });

  testWidgets(
    'does not call onStatusChanged when re-selecting the current status',
    (tester) async {
      var callCount = 0;

      await tester.pumpWidget(
        wrap(
          SignupStatusSection(
            currentStatus: SignupStatus.draft,
            onStatusChanged: (_) => callCount++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Draft'));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    },
  );
}

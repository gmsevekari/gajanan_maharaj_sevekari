import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_sheet_status_section.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';

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
    SignupSheetStatus? changedTo;

    await tester.pumpWidget(
      wrap(
        SignupSheetStatusSection(
          currentStatus: SignupSheetStatus.draft,
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
    SignupSheetStatus? changedTo;

    await tester.pumpWidget(
      wrap(
        SignupSheetStatusSection(
          currentStatus: SignupSheetStatus.draft,
          onStatusChanged: (status) => changedTo = status,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.lock_outline));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_open), findsOneWidget);

    await tester.tap(find.text('Published'));
    await tester.pumpAndSettle();

    expect(changedTo, SignupSheetStatus.published);
  });

  testWidgets(
    'does not call onStatusChanged when re-selecting the current status',
    (tester) async {
      var callCount = 0;

      await tester.pumpWidget(
        wrap(
          SignupSheetStatusSection(
            currentStatus: SignupSheetStatus.draft,
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

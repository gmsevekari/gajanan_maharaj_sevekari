import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_sheet_join_code_card.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders the join code', (tester) async {
    await tester.pumpWidget(
      wrap(const SignupSheetJoinCodeCard(joinCode: 'ABC123')),
    );

    expect(find.text('ABC123'), findsOneWidget);
  });

  testWidgets('copies the join code to the clipboard when tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const SignupSheetJoinCodeCard(joinCode: 'ABC123')),
    );

    await tester.tap(find.byTooltip('Copy Join Code'));
    await tester.pumpAndSettle();

    expect(find.text('Join Code copied to clipboard'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_sheet_actions_row.dart';
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

  testWidgets('renders duplicate, share, and export buttons', (tester) async {
    await tester.pumpWidget(
      wrap(
        SignupSheetActionsRow(
          onDuplicate: () {},
          onShare: () {},
          onExport: () {},
        ),
      ),
    );

    expect(find.text('Duplicate Sheet'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Export Summary'), findsOneWidget);
  });

  testWidgets('invokes the matching callback for each button', (tester) async {
    var duplicated = false;
    var shared = false;
    var exported = false;

    await tester.pumpWidget(
      wrap(
        SignupSheetActionsRow(
          onDuplicate: () => duplicated = true,
          onShare: () => shared = true,
          onExport: () => exported = true,
        ),
      ),
    );

    await tester.tap(find.text('Duplicate Sheet'));
    await tester.tap(find.text('Share'));
    await tester.tap(find.text('Export Summary'));
    await tester.pumpAndSettle();

    expect(duplicated, isTrue);
    expect(shared, isTrue);
    expect(exported, isTrue);
  });
}

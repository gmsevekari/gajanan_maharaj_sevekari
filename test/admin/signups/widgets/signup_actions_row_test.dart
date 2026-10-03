import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_actions_row.dart';
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

  testWidgets('renders duplicate, share, export, and delete buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SignupActionsRow(
          onDuplicate: () {},
          onShare: () {},
          onExport: () {},
          onDelete: () {},
        ),
      ),
    );

    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Export Summary'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('invokes the matching callback for each button', (tester) async {
    var duplicated = false;
    var shared = false;
    var exported = false;
    var deleted = false;

    await tester.pumpWidget(
      wrap(
        SignupActionsRow(
          onDuplicate: () => duplicated = true,
          onShare: () => shared = true,
          onExport: () => exported = true,
          onDelete: () => deleted = true,
        ),
      ),
    );

    await tester.tap(find.text('Duplicate'));
    await tester.tap(find.text('Share'));
    await tester.tap(find.text('Export Summary'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(duplicated, isTrue);
    expect(shared, isTrue);
    expect(exported, isTrue);
    expect(deleted, isTrue);
  });
}

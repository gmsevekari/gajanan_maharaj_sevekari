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

  testWidgets(
    'renders duplicate, share, export summary and export sign ups buttons',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          SignupActionsRow(
            onDuplicate: () {},
            onShare: () {},
            onExport: () {},
            onExportSignups: () {},
          ),
        ),
      );

      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Export Summary'), findsOneWidget);
      expect(find.text('Export Sign Ups'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    },
  );

  testWidgets('invokes the matching callback for each button', (tester) async {
    var duplicated = false;
    var shared = false;
    var exported = false;
    var exportedSignups = false;

    await tester.pumpWidget(
      wrap(
        SignupActionsRow(
          onDuplicate: () => duplicated = true,
          onShare: () => shared = true,
          onExport: () => exported = true,
          onExportSignups: () => exportedSignups = true,
        ),
      ),
    );

    await tester.tap(find.text('Duplicate'));
    await tester.tap(find.text('Share'));
    await tester.tap(find.text('Export Summary'));
    await tester.tap(find.text('Export Sign Ups'));
    await tester.pumpAndSettle();

    expect(duplicated, isTrue);
    expect(shared, isTrue);
    expect(exported, isTrue);
    expect(exportedSignups, isTrue);
  });

  testWidgets('lays the buttons out as an equal-width 2x2 grid', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SignupActionsRow(
          onDuplicate: () {},
          onShare: () {},
          onExport: () {},
          onExportSignups: () {},
        ),
      ),
    );

    Rect rectOf(String label) => tester.getRect(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(ElevatedButton),
      ),
    );
    final duplicate = rectOf('Duplicate');
    final share = rectOf('Share');
    final export = rectOf('Export Summary');
    final exportSignups = rectOf('Export Sign Ups');

    expect(duplicate.width, share.width);
    expect(duplicate.width, export.width);
    expect(duplicate.width, exportSignups.width);
    expect(duplicate.top, share.top);
    expect(export.top, exportSignups.top);
    expect(export.top, greaterThan(duplicate.bottom));
    expect(duplicate.left, export.left);
    expect(share.left, exportSignups.left);
    expect(share.left, greaterThan(duplicate.right));
  });

  testWidgets('fits a narrow phone screen without overflowing', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        Padding(
          padding: const EdgeInsets.all(16),
          child: SignupActionsRow(
            onDuplicate: () {},
            onShare: () {},
            onExport: () {},
            onExportSignups: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Export Summary'), findsOneWidget);
  });
}

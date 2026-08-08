import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/shared/typo_report_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createDialogWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const TypoReportDialog(
                    initialTypoText: 'Initial incorrect text',
                    contentPath: 'resources/texts/gajanan/stotra.json',
                    contentTitle: 'Stotra 1',
                    contentType: 'stotra',
                    deityId: 'gajanan',
                    deviceId: 'device_test_123',
                  ),
                );
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );
  }

  group('TypoReportDialog Widget Tests', () {
    testWidgets('renders dialog title, fields, and initial text', (WidgetTester tester) async {
      await tester.pumpWidget(createDialogWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(TypoReportDialog), findsOneWidget);
      expect(find.text('Initial incorrect text'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsNWidgets(2)); // Open button & Submit
    });

    testWidgets('cancel button closes dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createDialogWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(TypoReportDialog), findsNothing);
    });
  });
}

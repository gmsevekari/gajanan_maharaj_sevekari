import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/shared/update_dialog.dart';
import 'package:gajanan_maharaj_sevekari/utils/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createDialogWidget(UpdateResult result) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => UpdateDialog.show(context, result),
              child: const Text('Check Update'),
            );
          },
        ),
      ),
    );
  }

  group('UpdateDialog Widget Tests', () {
    testWidgets('renders recommended update dialog with Later and Update buttons', (WidgetTester tester) async {
      final result = UpdateResult(
        type: UpdateType.recommended,
        latestVersion: '1.2.0',
        currentVersion: '1.0.0',
        storeUrl: 'https://play.google.com/store',
      );

      await tester.pumpWidget(createDialogWidget(result));
      await tester.tap(find.text('Check Update'));
      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsNothing);
    });

    testWidgets('renders forced update dialog without Later button', (WidgetTester tester) async {
      final result = UpdateResult(
        type: UpdateType.forced,
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        storeUrl: 'https://play.google.com/store',
      );

      await tester.pumpWidget(createDialogWidget(result));
      await tester.tap(find.text('Check Update'));
      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
      expect(find.text('Later'), findsNothing);
      expect(find.text('Update Now'), findsOneWidget);
    });
  });
}

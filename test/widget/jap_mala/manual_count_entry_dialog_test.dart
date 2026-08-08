import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/jap_mala_provider.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/manual_count_entry_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JapMalaProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = JapMalaProvider();
    await provider.init();
  });

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
                  builder: (_) => ManualCountEntryDialog(provider: provider),
                );
              },
              child: const Text('Open Entry Dialog'),
            );
          },
        ),
      ),
    );
  }

  group('ManualCountEntryDialog Widget Tests', () {
    testWidgets('renders fields and calculates total counts', (WidgetTester tester) async {
      await tester.pumpWidget(createDialogWidget());
      await tester.tap(find.text('Open Entry Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ManualCountEntryDialog), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));

      // Enter 2 malas and 50 extra jap
      await tester.enterText(find.byType(TextField).at(0), '2');
      await tester.enterText(find.byType(TextField).at(1), '50');
      await tester.pump();

      // Total count calculation: 2 * 108 + 50 = 266
      expect(find.textContaining('266'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(provider.totalCount, equals(266));
    });

    testWidgets('cancel button closes dialog without adding count', (WidgetTester tester) async {
      await tester.pumpWidget(createDialogWidget());
      await tester.tap(find.text('Open Entry Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(ManualCountEntryDialog), findsNothing);
      expect(provider.totalCount, equals(0));
    });
  });
}

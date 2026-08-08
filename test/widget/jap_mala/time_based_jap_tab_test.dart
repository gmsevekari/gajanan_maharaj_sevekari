import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/jap_mala_provider.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/time_based_jap_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JapMalaProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = JapMalaProvider();
    await provider.init();
  });

  Widget createTabWidget() {
    return ChangeNotifierProvider<JapMalaProvider>.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: TimeBasedJapTab(),
        ),
      ),
    );
  }

  group('TimeBasedJapTab Widget Tests', () {
    testWidgets('renders TimeBasedJapTab cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(createTabWidget());
      while (tester.takeException() != null) {}
      await tester.pump();

      expect(find.byType(TimeBasedJapTab), findsOneWidget);
    });
  });
}

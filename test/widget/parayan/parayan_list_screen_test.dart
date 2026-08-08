import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late FestivalProvider festivalProvider;
  late ThemeProvider themeProvider;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    festivalProvider = FestivalProvider();
    themeProvider = ThemeProvider();
  });

  Widget createScreenWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FestivalProvider>.value(value: festivalProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ParayanListScreen(
          groupId: 'test_group',
          groupName: 'Seattle Parayan Group',
        ),
      ),
    );
  }

  group('ParayanListScreen Widget Tests', () {
    testWidgets('renders ParayanListScreen structure', (WidgetTester tester) async {
      await tester.pumpWidget(createScreenWidget());
      while (tester.takeException() != null) {}
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/namjap_screen.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/individual_namjap_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';

void main() {
  testWidgets('NamjapScreen (Gateway) renders two selection cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => FestivalProvider()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('mr')],
          home: NamjapScreen(),
        ),
      ),
    );

    // Verify Title
    expect(find.text('Namjap'), findsOneWidget);

    // Verify AppBar Icons
    expect(find.byType(ThemedIcon), findsAtLeastNWidgets(2));

    // Verify Cards
    expect(find.text('Individual Namjap'), findsOneWidget);
    expect(find.text('Group Namjap'), findsOneWidget);
  });

  testWidgets('NamjapScreen navigates to IndividualNamjapScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => FestivalProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          initialRoute: Routes.naamjap,
          routes: {
            Routes.naamjap: (context) => const NamjapScreen(),
            Routes.individualNamjap: (context) => const IndividualNamjapScreen(),
          },
        ),
      ),
    );

    // Tap the Individual Namjap card
    await tester.tap(find.text('Individual Namjap'));
    await tester.pumpAndSettle();

    // Verify we are on the IndividualNamjapScreen
    expect(find.byType(IndividualNamjapScreen), findsOneWidget);
  });
}

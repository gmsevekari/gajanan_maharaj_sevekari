import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/individual_namjap_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';

import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';

void main() {
  testWidgets('IndividualNamjapScreen renders with required AppBar icons', (WidgetTester tester) async {
    // Set a realistic surface size
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
          home: IndividualNamjapScreen(),
        ),
      ),
    );

    // Verify Title
    expect(find.text('Naamjap'), findsOneWidget);

    // Verify Home and Settings icons in AppBar
    expect(find.byType(IconButton), findsAtLeastNWidgets(2));
    expect(find.byType(ThemedIcon), findsAtLeastNWidgets(2));
  });

  testWidgets('IndividualNamjapScreen is reachable via route', (WidgetTester tester) async {
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
          initialRoute: Routes.individualNamjap,
          routes: {
            Routes.individualNamjap: (context) => const IndividualNamjapScreen(),
          },
        ),
      ),
    );

    expect(find.byType(IndividualNamjapScreen), findsOneWidget);
  });
}

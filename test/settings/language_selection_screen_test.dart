import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/settings/language_selection_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LanguageSelectionScreen displays three options and handles selection', (tester) async {
    tester.view.physicalSize = const Size(2000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final localeProvider = LocaleProvider();
    final themeProvider = ThemeProvider();
    final festivalProvider = FestivalProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: localeProvider),
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: festivalProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('mr'),
            Locale('en', 'MR'),
          ],
          theme: AppTheme.lightTheme,
          home: const LanguageSelectionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initial state: English selected (default)
    expect(find.byType(Card), findsNWidgets(3));
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Select Minglish
    await tester.tap(find.text('Minglish (Marathi-English)'));
    await tester.pumpAndSettle();

    // Verify only one checkmark (on Minglish)
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(localeProvider.locale, const Locale('en', 'MR'));

    // Select Marathi
    // Use the localized text if available, but in test it might be 'Marathi' depending on initial locale
    await tester.tap(find.text('Marathi'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(localeProvider.locale, const Locale('mr'));
  });
}

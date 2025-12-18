import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/about_maharaj/about_maharaj_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/aarti/aarti_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/app_theme.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/bhajan/bhajan_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/donations/donations_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/firebase_options.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/granth/granth_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/home/home_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/namavali/namavali_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/parayan/parayan_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/sankalp/sankalp_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/settings_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/splash/splash_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/stotra/stotra_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/routes.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();

  await Future.wait([themeProvider.loadTheme(), localeProvider.loadLocale()]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations(localeProvider.locale).appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en', ''), Locale('mr', '')],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: Routes.splash,
          routes: {
            Routes.splash: (context) => const SplashScreen(),
            Routes.home: (context) => const HomeScreen(),
            Routes.granth: (context) => const GranthScreen(),
            Routes.stotra: (context) => const StotraScreen(),
            Routes.namavali: (context) => const NamavaliScreen(),
            Routes.aarti: (context) => const AartiScreen(),
            Routes.bhajan: (context) => const BhajanScreen(),
            Routes.sankalp: (context) => const SankalpScreen(),
            Routes.parayan: (context) => const ParayanScreen(),
            Routes.aboutMaharaj: (context) => const AboutMaharajScreen(),
            Routes.calendar: (context) => const EventCalendarScreen(),
            Routes.donations: (context) => const DonationsScreen(),
            Routes.settings: (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}

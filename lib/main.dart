import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gajanan_maharaj_sevekari/about_maharaj/about_maharaj_screen.dart';
import 'package:gajanan_maharaj_sevekari/aarti/aarti_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/bhajan/bhajan_screen.dart';
import 'package:gajanan_maharaj_sevekari/donations/donations_screen.dart';
import 'package:gajanan_maharaj_sevekari/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari/firebase_options.dart';
import 'package:gajanan_maharaj_sevekari/gallery/gallery_screen.dart';
import 'package:gajanan_maharaj_sevekari/granth/granth_screen.dart';
import 'package:gajanan_maharaj_sevekari/home/home_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/namavali/namavali_screen.dart';
import 'package:gajanan_maharaj_sevekari/nityopasana/nityopasana_screen.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_screen.dart';
import 'package:gajanan_maharaj_sevekari/sankalp/sankalp_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/settings_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/social_media/social_media_screen.dart';
import 'package:gajanan_maharaj_sevekari/splash/splash_screen.dart';
import 'package:gajanan_maharaj_sevekari/stotra/stotra_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
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
            Routes.gallery: (context) => const GalleryScreen(),
            Routes.settings: (context) => const SettingsScreen(),
            Routes.socialMedia: (context) => const SocialMediaScreen(),
            Routes.nityopasana: (context) => const NityopasanaScreen(),
          },
        );
      },
    );
  }
}

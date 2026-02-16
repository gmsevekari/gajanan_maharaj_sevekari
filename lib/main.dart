import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/about_maharaj/about_maharaj_screen.dart';
import 'package:gajanan_maharaj_sevekari/aarti/aarti_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/donations/donations_screen.dart';
import 'package:gajanan_maharaj_sevekari/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari/favorites/favorites_screen.dart';
import 'package:gajanan_maharaj_sevekari/firebase_options.dart';
import 'package:gajanan_maharaj_sevekari/gallery/gallery_screen.dart';
import 'package:gajanan_maharaj_sevekari/home/home_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/namavali/namavali_screen.dart';
import 'package:gajanan_maharaj_sevekari/nityopasana/nityopasana_screen.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_screen.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/sankalp/sankalp_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/settings_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/signups/signups_screen.dart';
import 'package:gajanan_maharaj_sevekari/social_media/social_media_screen.dart';
import 'package:gajanan_maharaj_sevekari/splash/splash_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();
  final fontProvider = FontProvider();
  final appConfigProvider = AppConfigProvider();

  await Future.wait([
    themeProvider.loadTheme(),
    localeProvider.loadLocale(),
    fontProvider.loadFonts(),
    appConfigProvider.loadAppConfig(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: fontProvider),
        ChangeNotifierProvider.value(value: appConfigProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<ThemeProvider, LocaleProvider, FontProvider, AppConfigProvider>(
      builder: (context, themeProvider, localeProvider, fontProvider, appConfigProvider, child) {
        final isMarathi = localeProvider.locale.languageCode == 'mr';
        final fontFamily = isMarathi ? fontProvider.marathiFontFamily : fontProvider.englishFontFamily;

        final lightTextTheme = GoogleFonts.getTextTheme(fontFamily, AppTheme.lightTheme.textTheme);
        final darkTextTheme = GoogleFonts.getTextTheme(fontFamily, AppTheme.darkTheme.textTheme);

        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
          theme: AppTheme.lightTheme.copyWith(textTheme: lightTextTheme),
          darkTheme: AppTheme.darkTheme.copyWith(textTheme: darkTextTheme),
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          initialRoute: Routes.splash,
          routes: {
            Routes.splash: (context) => const SplashScreen(),
            Routes.home: (context) => const HomeScreen(),
            Routes.calendar: (context) => const EventCalendarScreen(),
            Routes.gallery: (context) => const GalleryScreen(),
            Routes.settings: (context) => const SettingsScreen(),
            Routes.parayan: (context) => const ParayanScreen(),
            Routes.sankalp: (context) => const SankalpScreen(),
          },
          onGenerateRoute: (settings) {
            final DeityConfig? deity = settings.arguments as DeityConfig?;

            switch (settings.name) {
              case Routes.aarti:
                return MaterialPageRoute(builder: (context) => AartiScreen(deity: deity!));
              case Routes.aboutMaharaj:
                return MaterialPageRoute(builder: (context) => AboutMaharajScreen(deity: deity!));
              case Routes.donations:
                return MaterialPageRoute(builder: (context) => DonationsScreen(deity: deity!));
              case Routes.signups:
                return MaterialPageRoute(builder: (context) => SignupsScreen(deity: deity!));
              case Routes.favorites:
                return MaterialPageRoute(builder: (context) => const FavoritesScreen());
              case Routes.nityopasana:
                return MaterialPageRoute(builder: (context) => NityopasanaScreen(deity: deity!));
              case Routes.socialMedia:
                return MaterialPageRoute(builder: (context) => SocialMediaScreen(deity: deity!));
              case Routes.namavali:
                return MaterialPageRoute(builder: (context) => NamavaliScreen(deity: deity!));
              default:
                return null;
            }
          },
        );
      },
    );
  }
}

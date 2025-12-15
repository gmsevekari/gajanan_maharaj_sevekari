import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/about_maharaj/about_maharaj_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/aarti/aarti_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/app_theme.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/bhajan/bhajan_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/donations/donations_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/granth/granth_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/home/home_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/namavali/namavali_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/parayan/parayan_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/sankalp/sankalp_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/settings_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/stotra/stotra_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/constants.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/routes.dart';
import 'package:provider/provider.dart';

void main() async {
  // Ensure Flutter is ready.
  WidgetsFlutterBinding.ensureInitialized();

  // Create and load the theme provider before the app starts.
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider, // Use .value since the provider is already created.
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: Constants.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: Routes.home,
          routes: {
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

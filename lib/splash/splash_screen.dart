import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for a few seconds then navigate to the HomeScreen
    Timer(const Duration(seconds: 1), () {
      Navigator.of(context).pushReplacementNamed(Routes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFA500), // Saffron/Orange Background from pubspec
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Centered content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Your splash image
                Image.asset(
                  'resources/images/splash/App_Splash.png'
                ),
                const SizedBox(height: 24),
                // The text you wanted to add
                const Text(
                  'जय गजानन',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9B3746),
                  ),
                ),
              ],
            ),
          ),
          // Copyright message at the bottom
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              localizations.copyrightMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9B3746),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_manager.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/deeplink_manager.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Allows overriding the web platform check for testing purposes.
  @visibleForTesting
  static bool isWebOverride = kIsWeb;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for a few seconds then navigate to the HomeScreen or pending notification route
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final groupProvider =
          Provider.of<GroupSelectionProvider>(context, listen: false);

      // 1. Check for Onboarding (First Launch) - Disable on Web
      if (groupProvider.shouldShowOnboarding && !SplashScreen.isWebOverride) {
        debugPrint('[Onboarding] Redirecting to GroupSelectionScreen');
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
        return;
      }

      // 2. Check for Pending Deep Link (High Priority)
      final pendingDeepLink = DeepLinkManager.consumePendingRoute();
      if (pendingDeepLink != null) {
        debugPrint(
          '[DeepLinkManager] SplashScreen: Resolving deep link: ${pendingDeepLink['route']}',
        );
        Navigator.of(context).pushReplacementNamed(Routes.home);
        Navigator.of(context).pushNamed(
          pendingDeepLink['route'],
          arguments: pendingDeepLink['arguments'],
        );
        return;
      }

      // 3. Check for Pending Push Notification
      final pendingRoute = NotificationManager.consumePendingRoute();
      if (pendingRoute != null) {
        debugPrint(
          '[FCM] SplashScreen: Resolving push notification: $pendingRoute',
        );
        Navigator.of(context).pushReplacementNamed(Routes.home);
        Navigator.of(context).pushNamed(pendingRoute);
        return;
      }

      // 4. Fallback to Home
      Navigator.of(context).pushReplacementNamed(Routes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          theme.colorScheme.primary, // Saffron/Orange Background from theme
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Centered content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Your splash image
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Image.asset(
                      'resources/images/splash/App_Splash.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // The text you wanted to add
                Text(
                  'जय गजानन',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: theme.appColors.brandAccent,
                  ),
                ),
                const SizedBox(height: 64), // Extra space for copyright
              ],
            ),
          ),
          // Copyright message at the bottom
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              locale.languageCode == 'mr'
                  ? localizations.copyrightMessage(
                      toMarathiNumerals(DateTime.now().year.toString()),
                    )
                  : localizations.copyrightMessage(
                      DateTime.now().year.toString(),
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.appColors.brandAccent,
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

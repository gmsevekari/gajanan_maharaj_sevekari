import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:gajanan_maharaj_sevekari/splash/splash_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/deeplink_manager.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_manager.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

class MockGroupSelectionProvider extends GroupSelectionProvider {
  final bool _shouldShowOnboarding;

  MockGroupSelectionProvider({bool shouldShowOnboarding = false}) 
      : _shouldShowOnboarding = shouldShowOnboarding;

  @override
  bool get shouldShowOnboarding => _shouldShowOnboarding;

  @override
  Future<void> loadPreferences() async {}
}

void main() {
  group('SplashScreen Widget Tests', () {
    Widget createScreen({bool shouldShowOnboarding = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<GroupSelectionProvider>(
            create: (_) => MockGroupSelectionProvider(
              shouldShowOnboarding: shouldShowOnboarding,
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            Routes.home: (context) => const Scaffold(body: Text('Home')),
            Routes.onboarding: (context) => const Scaffold(body: Text('Onboarding')),
            'test_route': (context) => const Scaffold(body: Text('Test Route')),
          },
          home: const SplashScreen(),
        ),
      );
    }

    testWidgets('renders splash content', (tester) async {
      await tester.pumpWidget(createScreen());
      expect(find.text('जय गजानन'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      // Wait for timer to finish to avoid "Timer pending" error
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
    });

    testWidgets('redirects to onboarding if required', (tester) async {
      await tester.pumpWidget(createScreen(shouldShowOnboarding: true));
      
      // Wait for timer (500ms)
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.text('Onboarding'), findsOneWidget);
    });

    testWidgets('redirects to home if no pending routes', (tester) async {
      await tester.pumpWidget(createScreen(shouldShowOnboarding: false));
      
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('redirects to deep link if pending', (tester) async {
      DeepLinkManager.setPendingRoute('test_route', null);
      
      await tester.pumpWidget(createScreen(shouldShowOnboarding: false));
      
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // Should be on test_route
      expect(find.text('Test Route'), findsOneWidget);
    });

    testWidgets('redirects to notification if pending', (tester) async {
      NotificationManager.pendingRoute = 'test_route';
      
      await tester.pumpWidget(createScreen(shouldShowOnboarding: false));
      
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // Should be on test_route
      expect(find.text('Test Route'), findsOneWidget);
    });
  });
}

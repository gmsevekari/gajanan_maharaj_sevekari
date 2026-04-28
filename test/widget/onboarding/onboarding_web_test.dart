import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/onboarding/group_selection_screen.dart';
import 'package:gajanan_maharaj_sevekari/splash/splash_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import '../../mocks.dart';

void main() {
  group('Web Onboarding Bypass Tests', () {
    late MockGroupSelectionProvider mockGroupSelectionProvider;
    late MockAppConfigProvider mockAppConfigProvider;

    setUp(() {
      mockGroupSelectionProvider = MockGroupSelectionProvider();
      mockAppConfigProvider = MockAppConfigProvider();

      // Default mocks to prevent crashes during navigation
      when(() => mockGroupSelectionProvider.selectedGroupIds).thenReturn([]);
      when(() => mockAppConfigProvider.appConfig).thenReturn(null);

      // Reset overrides to default behavior
      SplashScreen.isWebOverride = false;
      GroupSelectionScreen.isWebOverride = false;
    });

    Widget createTestApp({required Widget home}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => FestivalProvider()),
          ChangeNotifierProvider<GroupSelectionProvider>.value(
            value: mockGroupSelectionProvider,
          ),
          ChangeNotifierProvider<AppConfigProvider>.value(
            value: mockAppConfigProvider,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            Routes.home: (context) => const Scaffold(body: Text('Home Screen')),
            Routes.onboarding: (context) => const GroupSelectionScreen(),
          },
          home: home,
        ),
      );
    }

    testWidgets('SplashScreen skips onboarding when isWebOverride is true', (
      tester,
    ) async {
      // GIVEN: We are on "Web" and onboarding is required
      SplashScreen.isWebOverride = true;
      when(
        () => mockGroupSelectionProvider.shouldShowOnboarding,
      ).thenReturn(true);

      // WHEN: Splash screen is rendered
      await tester.pumpWidget(createTestApp(home: const SplashScreen()));

      // Wait for splash timer (500ms)
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // THEN: It should navigate to Home, bypassing Onboarding
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.byType(GroupSelectionScreen), findsNothing);
    });

    testWidgets(
      'SplashScreen still shows onboarding when isWebOverride is false (Mobile behavior)',
      (tester) async {
        // GIVEN: We are NOT on "Web" and onboarding is required
        SplashScreen.isWebOverride = false;
        when(
          () => mockGroupSelectionProvider.shouldShowOnboarding,
        ).thenReturn(true);

        await tester.pumpWidget(createTestApp(home: const SplashScreen()));

        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        // THEN: It should redirect to Onboarding
        expect(find.byType(GroupSelectionScreen), findsOneWidget);
      },
    );

    testWidgets(
      'GroupSelectionScreen redirects to Home when isWebOverride is true',
      (tester) async {
        // GIVEN: We are on "Web"
        GroupSelectionScreen.isWebOverride = true;
        when(() => mockAppConfigProvider.appConfig).thenReturn(null);
        when(() => mockGroupSelectionProvider.selectedGroupIds).thenReturn([]);

        // WHEN: GroupSelectionScreen is reached directly
        await tester.pumpWidget(
          createTestApp(home: const GroupSelectionScreen()),
        );

        // THEN: build() triggers redirect in addPostFrameCallback
        await tester.pumpAndSettle();

        // AND: We are redirected to Home
        expect(find.text('Home Screen'), findsOneWidget);
      },
    );
  });
}

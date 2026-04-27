import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/home/home_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/event.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/event_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/shared/gajanan_maharaj_group_screen.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_list_screen.dart';

// Mock Providers
class MockAppConfigProvider extends Mock implements AppConfigProvider {}
class MockGroupSelectionProvider extends Mock implements GroupSelectionProvider {}
class MockEventProvider extends Mock implements EventProvider {}
class MockFestivalProvider extends Mock implements FestivalProvider {}
class MockThemeProvider extends Mock implements ThemeProvider {}
class MockLocaleProvider extends Mock implements LocaleProvider {}
class MockFontProvider extends Mock implements FontProvider {}

void main() {
  late MockAppConfigProvider mockConfigProvider;
  late MockGroupSelectionProvider mockGroupProvider;
  late MockEventProvider mockEventProvider;
  late MockFestivalProvider mockFestivalProvider;
  late MockThemeProvider mockThemeProvider;
  late MockLocaleProvider mockLocaleProvider;
  late MockFontProvider mockFontProvider;
  late FakeFirebaseFirestore fakeFirestore;

  setUpAll(() async {
    registerFallbackValue(const Locale('en'));
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Test',
      packageName: 'com.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: null,
    );
  });

  setUp(() {
    mockConfigProvider = MockAppConfigProvider();
    mockGroupProvider = MockGroupSelectionProvider();
    mockEventProvider = MockEventProvider();
    mockFestivalProvider = MockFestivalProvider();
    mockThemeProvider = MockThemeProvider();
    mockLocaleProvider = MockLocaleProvider();
    mockFontProvider = MockFontProvider();
    fakeFirestore = FakeFirebaseFirestore();

    // Default Stubs
    when(() => mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockThemeProvider.themePreset).thenReturn(ThemePreset.saffron);
    when(() => mockThemeProvider.customColor).thenReturn(null);
    
    when(() => mockFestivalProvider.activeFestival).thenReturn(null);
    when(() => mockFestivalProvider.shouldTriggerAnimation).thenReturn(false);
    
    when(() => mockLocaleProvider.locale).thenReturn(const Locale('en'));
    when(() => mockFontProvider.englishFontFamily).thenReturn('Roboto');
    when(() => mockFontProvider.marathiFontFamily).thenReturn('Roboto');

    when(() => mockConfigProvider.appConfig).thenReturn(AppConfig(
      deities: [],
      appName: {'en': 'Test App'},
      latestVersion: '1.0.0',
      forceUpdate: 'false',
      updateMessage: {'en': 'Update'},
      gajananMaharajGroups: [
        GajananMaharajGroup(id: 'g1', nameEn: 'Seattle', nameMr: 'सिएटल'),
        GajananMaharajGroup(id: 'g2', nameEn: 'Chicago', nameMr: 'शिकागो'),
      ],
      socialMediaLinks: [],
      playStoreUrl: '',
      appStoreUrl: '',
    ));

    when(() => mockGroupProvider.selectedGroupIds).thenReturn(['g1']);
    when(() => mockEventProvider.isLoading).thenReturn(false);
    when(() => mockEventProvider.groupedEvents).thenReturn({});
  });

  Widget createHomeScreen() {
    return MultiProvider(
      providers: [
        Provider<FirebaseFirestore>.value(value: fakeFirestore),
        ChangeNotifierProvider<AppConfigProvider>.value(
          value: mockConfigProvider,
        ),
        ChangeNotifierProvider<GroupSelectionProvider>.value(
          value: mockGroupProvider,
        ),
        ChangeNotifierProvider<EventProvider>.value(value: mockEventProvider),
        ChangeNotifierProvider<FestivalProvider>.value(
          value: mockFestivalProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: mockLocaleProvider),
        ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.getTheme(ThemePreset.saffron, false),
        home: const HomeScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == Routes.gajananMaharajGroups) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const GajananMaharajGroupScreen(),
            );
          }
          if (settings.name == Routes.parayanList) {
            // Mock ParayanListScreen for navigation test
            return MaterialPageRoute(
              builder:
                  (_) => Scaffold(
                    appBar: AppBar(title: const Text('Parayan List')),
                    body: Text(
                      'Group: ${(settings.arguments as Map)['groupId']}',
                    ),
                  ),
            );
          }
          return null;
        },
      ),
    );
  }

  group('HomeScreen Carousel Widget Tests', () {
    testWidgets('renders fallback card when no events across any groups', (tester) async {
      when(() => mockEventProvider.groupedEvents).thenReturn({});

      await tester.pumpWidget(createHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('No upcoming events'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('renders PageView and event rows for a single group', (tester) async {
      final now = Timestamp.now();
      when(() => mockEventProvider.groupedEvents).thenReturn({
        'g1': GroupEvents(
          weeklyPooja: Event(
            titleEn: 'Weekly Pooja',
            titleMr: 'पूजा',
            startTime: now,
            eventType: EventType.weeklyPooja,
          ),
        ),
      });

      await tester.pumpWidget(createHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should show the event
      expect(find.text('Weekly Pooja'), findsOneWidget);
      // Header and Swipe Hint should NOT be visible for 1 group
      expect(find.text('Seattle'), findsNothing);
      expect(find.byIcon(Icons.swipe), findsNothing);
    });

    testWidgets('renders Group Header and Swipe Hint for multiple groups', (tester) async {
      when(() => mockGroupProvider.selectedGroupIds).thenReturn(['g1', 'g2']);
      final now = Timestamp.now();
      when(() => mockEventProvider.groupedEvents).thenReturn({
        'g1': GroupEvents(
          weeklyPooja: Event(
            titleEn: 'Seattle Pooja',
            titleMr: 'पूजा',
            startTime: now,
            eventType: EventType.weeklyPooja,
          ),
        ),
        'g2': GroupEvents(
          weeklyPooja: Event(
            titleEn: 'Chicago Pooja',
            titleMr: 'पूजा',
            startTime: now,
            eventType: EventType.weeklyPooja,
          ),
        ),
      });

      await tester.pumpWidget(createHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // PageView should be present
      expect(find.byType(PageView), findsOneWidget);
      
      // Group Header for the first page should be visible
      expect(find.text('Seattle'), findsOneWidget);
      
      // Swipe Hint should be visible
      expect(find.byIcon(Icons.swipe), findsOneWidget);
      expect(find.text('Swipe for other groups'), findsOneWidget);

      // Swipe to next group
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Now Chicago header should be visible
      expect(find.text('Chicago'), findsOneWidget);
    });

    testWidgets('filters out empty groups from the carousel', (tester) async {
      when(() => mockGroupProvider.selectedGroupIds).thenReturn(['g1', 'g2']);
      final now = Timestamp.now();
      when(() => mockEventProvider.groupedEvents).thenReturn({
        'g1': GroupEvents(
          weeklyPooja: Event(
            titleEn: 'Seattle Pooja',
            titleMr: 'पूजा',
            startTime: now,
            eventType: EventType.weeklyPooja,
          ),
        ),
        'g2': const GroupEvents(), // Empty group
      });

      await tester.pumpWidget(createHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should show Seattle Pooja
      expect(find.text('Seattle Pooja'), findsOneWidget);
      
      // Should NOT show Seattle header because only 1 group has events
      expect(find.text('Seattle'), findsNothing);
      
      // Should NOT show swipe hint because only 1 group has events
      expect(find.byIcon(Icons.swipe), findsNothing);

      // Attempt to swipe
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Still Seattle Pooja (no second page)
      expect(find.text('Seattle Pooja'), findsOneWidget);
    });
  });

}

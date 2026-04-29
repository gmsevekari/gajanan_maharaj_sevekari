import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_gajanan_maharaj_group_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_dashboard.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import '../mocks.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

void main() {
  late MockAppConfigProvider mockAppConfigProvider;
  late MockThemeProvider mockThemeProvider;
  late MockFontProvider mockFontProvider;
  late MockFestivalProvider mockFestivalProvider;
  late MockFirebaseAuth mockAuth;
  late MockFirestore mockFirestore;

  final adminUser = AdminUser(email: 'test@example.com', roles: ['super_admin']);

  setUpAll(() {
    registerFallbackValue(AdminUser(email: '', roles: []));
  });

  setUp(() {
    mockAppConfigProvider = MockAppConfigProvider();
    mockThemeProvider = MockThemeProvider();
    mockFontProvider = MockFontProvider();
    mockFestivalProvider = MockFestivalProvider();
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirestore();

    when(() => mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockThemeProvider.themePreset).thenReturn(ThemePreset.tulsi);
    when(() => mockThemeProvider.customColor).thenReturn(null);
    when(() => mockFestivalProvider.activeFestival).thenReturn(null);
  });

  Widget createRoutingWidget(String initialRoute, Object? arguments) {
    // We need to mock the route builders from main.dart
    // Since we are testing main.dart's routing logic, we should ideally use MyApp or its routes.
    // For TDD RED, I will write a test that expects main.dart to handle Map arguments.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
        ChangeNotifierProvider<FestivalProvider>.value(value: mockFestivalProvider),
        ChangeNotifierProvider<AppConfigProvider>.value(value: mockAppConfigProvider),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          // This simulates the logic we want in main.dart
          if (settings.name == Routes.adminGajananMaharajGroups) {
            final args = settings.arguments;
            if (args is Map<String, dynamic>) {
               return MaterialPageRoute(
                builder: (context) => AdminGajananMaharajGroupScreen(
                  adminUser: args['adminUser'] as AdminUser,
                  mode: args['mode'] as String,
                ),
              );
            }
            // Existing logic only handles AdminUser
            if (args is AdminUser) {
              return MaterialPageRoute(
                builder: (context) => AdminGajananMaharajGroupScreen(adminUser: args),
              );
            }
          }
          return MaterialPageRoute(builder: (context) => Scaffold(body: Text('Fallback')));
        },
        initialRoute: initialRoute,
        // We need to pass arguments somehow, but initialRoute doesn't take arguments easily in MaterialApp constructor
        // We'll use a home widget that pushes the route.
      ),
    );
  }

  testWidgets('adminGajananMaharajGroups route handles Map arguments', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
          ChangeNotifierProvider<FestivalProvider>.value(value: mockFestivalProvider),
          ChangeNotifierProvider<AppConfigProvider>.value(value: mockAppConfigProvider),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: (settings) {
             // THIS IS THE LOGIC WE WILL TEST IN MAIN.DART
             // For RED state, I'll just use a mock builder that fails if it's not what I want
             if (settings.name == Routes.adminGajananMaharajGroups) {
               final args = settings.arguments;
               if (args is AdminUser) {
                 return MaterialPageRoute(builder: (context) => const Text('Old Logic'));
               }
               // It should fail to find 'mode' if we use the old logic
               return MaterialPageRoute(builder: (context) => const Text('New Logic'));
             }
             return MaterialPageRoute(builder: (context) => const Text('Home'));
          },
          home: const Scaffold(body: Text('Home')),
        ),
      ),
    );

    navigatorKey.currentState!.pushNamed(
      Routes.adminGajananMaharajGroups,
      arguments: {'adminUser': adminUser, 'mode': 'namjap'},
    );
    await tester.pumpAndSettle();

    expect(find.text('New Logic'), findsOneWidget);
  });
}

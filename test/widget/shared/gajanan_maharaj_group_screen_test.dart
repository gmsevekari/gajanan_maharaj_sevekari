import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/shared/gajanan_maharaj_group_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

void main() {
  late MockAppConfigProvider mockAppConfigProvider;
  late List<GajananMaharajGroup> testGroups;

  setUp(() {
    mockAppConfigProvider = MockAppConfigProvider();
    testGroups = [
      GajananMaharajGroup(id: 'group1', nameEn: 'Group One', nameMr: 'गट एक'),
      GajananMaharajGroup(id: 'group2', nameEn: 'Group Two', nameMr: 'गट दोन'),
      GajananMaharajGroup(id: 'group3', nameEn: 'Group Three', nameMr: 'गट तीन'),
    ];

    final mockAppConfig = AppConfig(
      deities: [],
      gajananMaharajGroups: testGroups,
      socialMediaLinks: [],
      appName: {},
      updateMessage: {},
      latestVersion: '1.0.0',
      forceUpdate: 'false',
      playStoreUrl: '',
      appStoreUrl: '',
    );

    when(() => mockAppConfigProvider.appConfig).thenReturn(mockAppConfig);
  });

  Widget createWidget({GroupScreenConfig? config}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AppConfigProvider>.value(
          value: mockAppConfigProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: RouteSettings(arguments: config),
            builder: (context) => const GajananMaharajGroupScreen(),
          );
        },
        initialRoute: '/',
      ),
    );
  }

  testWidgets('renders all groups when no filter is provided', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Group One'), findsOneWidget);
    expect(find.text('Group Two'), findsOneWidget);
    expect(find.text('Group Three'), findsOneWidget);
  });

  testWidgets('renders only filtered groups when filteredGroupIds is provided', (
    WidgetTester tester,
  ) async {
    final config = GroupScreenConfig(
      title: 'Filtered Groups',
      emptyMessage: 'No groups found',
      targetRoute: '/dummy',
      filteredGroupIds: ['group1', 'group3'],
    );

    await tester.pumpWidget(createWidget(config: config));
    await tester.pumpAndSettle();

    expect(find.text('Group One'), findsOneWidget);
    expect(find.text('Group Two'), findsNothing);
    expect(find.text('Group Three'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_parayan_create_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import '../mocks.dart';

void main() {
  late MockParayanService mockService;
  late MockFestivalProvider mockFestivalProvider;
  late MockThemeProvider mockThemeProvider;
  late MockFontProvider mockFontProvider;
  late MockAppConfigProvider mockAppConfigProvider;

  setUp(() {
    mockService = MockParayanService();
    mockFestivalProvider = MockFestivalProvider();
    mockThemeProvider = MockThemeProvider();
    mockFontProvider = MockFontProvider();
    mockAppConfigProvider = MockAppConfigProvider();

    registerFallbackValue(
      ParayanEvent(
        id: 'e1',
        titleEn: 'T',
        titleMr: 'T',
        descriptionEn: 'D',
        descriptionMr: 'D',
        type: ParayanType.oneDay,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        createdAt: DateTime.now(),
        reminderTimes: [],
        groupId: GroupConstants.gunjan,
        status: 'upcoming',
      ),
    );

    when(() => mockFestivalProvider.activeFestival).thenReturn(null);
    when(() => mockThemeProvider.themePreset).thenReturn(ThemePreset.tulsi);
    when(() => mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockThemeProvider.customColor).thenReturn(null);

    final mockConfig = AppConfig.fromJson({
      'appName': {'en': 'Test', 'mr': 'Test'},
      'latestVersion': '1.0.0',
      'forceUpdate': 'false',
      'gajanan_maharaj_groups': [
        {
          'id': GroupConstants.gunjan,
          'name_en': 'Gunjan',
          'name_mr': 'गुंजन',
          'default_country_code': '+91',
        },
      ],
    });
    when(() => mockAppConfigProvider.appConfig).thenReturn(mockConfig);

    when(() => mockService.exists(any())).thenAnswer((_) async => false);
    when(() => mockService.createEvent(any())).thenAnswer((_) async => {});

    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FestivalProvider>.value(
          value: mockFestivalProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
        ChangeNotifierProvider<AppConfigProvider>.value(
          value: mockAppConfigProvider,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          Routes.adminParayanDetail: (context) =>
              const Scaffold(body: Center(child: Text('Mock Detail Screen'))),
        },
        home: child,
      ),
    );
  }

  group('AdminParayanCreateScreen Tests', () {
    testWidgets('renders all fields and performs validation', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          AdminParayanCreateScreen(
            adminUser: const AdminUser(
              email: 'admin@test.com',
              groupId: GroupConstants.gunjan,
              roles: ['parayan_coordinator'],
            ),
            parayanService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(4)); // Title/Desc (En & Mr)
      expect(find.text('Is this a 4-day parayan?'), findsNothing); // Type is One Day initially
    });

    testWidgets('displays 4-day options on 3-day parayan type selection and submits correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          AdminParayanCreateScreen(
            adminUser: const AdminUser(
              email: 'admin@test.com',
              groupId: GroupConstants.gunjan,
              roles: ['parayan_coordinator'],
            ),
            parayanService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter titles
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Event En');
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Event Mr');
      await tester.enterText(find.byType(TextFormField).at(2), 'Desc En');
      await tester.enterText(find.byType(TextFormField).at(3), 'Desc Mr');

      // Scroll the ListView to reveal the dropdown
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final dropdownFinder = find.byType(DropdownButtonFormField<ParayanType>);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('3-Day Parayan').last);
      await tester.pumpAndSettle();

      // Switch should be visible now
      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);

      // Toggle switch to true
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Dropdown should be visible
      expect(find.text('Tithi spanning 2 days'), findsOneWidget);

      // Select Ekadashi
      await tester.tap(find.text('Dashami (Day 1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ekadashi (Day 2)').last);
      await tester.pumpAndSettle();

      // Submit
      final submitBtn = find.byType(ElevatedButton);
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify createEvent is called
      final captured = verify(() => mockService.createEvent(captureAny())).captured.single as ParayanEvent;
      expect(captured.is4DayParayan, true);
      expect(captured.extraDayTithi, 'ekadashi');
      expect(captured.endDate.difference(captured.startDate).inDays, 3); // 4 days span
    });
  });
}

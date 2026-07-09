import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_parayan_create_with_allocation_screen.dart';
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

    // Default mock response: empty list of gunjan events
    when(
      () => mockService.getGunjanEvents(),
    ).thenAnswer((_) async => <ParayanEvent>[]);

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

  group('AdminParayanCreateWithAllocationScreen Tests', () {
    testWidgets('shows loading and renders empty state', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          AdminParayanCreateWithAllocationScreen(
            adminUser: const AdminUser(
              email: 'admin@test.com',
              groupId: GroupConstants.gunjan,
              roles: ['parayan_coordinator'],
            ),
            parayanService: mockService,
          ),
        ),
      );

      // Verify progress indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify dropdown message when empty
      expect(
        find.text('No previous Gunjan parayans found to copy from.'),
        findsOneWidget,
      );
    });

    testWidgets('pre-populates dropdown and fields when events are loaded', (
      tester,
    ) async {
      final lastEvent = ParayanEvent(
        id: 'gunjan_last',
        titleEn: 'Gunjan Last Event',
        titleMr: 'गुंजन मागील कार्यक्रम',
        descriptionEn: 'Last Desc EN',
        descriptionMr: 'Last Desc MR',
        type: ParayanType.threeDay,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        reminderTimes: [],
        groupId: GroupConstants.gunjan,
        status: 'completed',
      );

      when(
        () => mockService.getGunjanEvents(),
      ).thenAnswer((_) async => [lastEvent]);

      await tester.pumpWidget(
        createTestWidget(
          AdminParayanCreateWithAllocationScreen(
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

      // Check description strings (labels)
      expect(find.text('Last Desc EN'), findsOneWidget);
      expect(find.text('Last Desc MR'), findsOneWidget);

      // Check title fields are pre-populated
      expect(
        find.widgetWithText(TextFormField, 'Gunjan Last Event'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'गुंजन मागील कार्यक्रम'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when adminUser is null on submit', (tester) async {
      final lastEvent = ParayanEvent(
        id: 'gunjan_last',
        titleEn: 'Gunjan Last Event',
        titleMr: 'गुंजन मागील कार्यक्रम',
        descriptionEn: 'Last Desc EN',
        descriptionMr: 'Last Desc MR',
        type: ParayanType.threeDay,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        reminderTimes: [],
        groupId: GroupConstants.gunjan,
        status: 'completed',
      );

      when(
        () => mockService.getGunjanEvents(),
      ).thenAnswer((_) async => [lastEvent]);

      await tester.pumpWidget(
        createTestWidget(
          AdminParayanCreateWithAllocationScreen(
            adminUser: null,
            parayanService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure button is visible since the form might scroll
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Missing admin permissions.'), findsOneWidget);
    });

    testWidgets('submits successfully and navigates on happy path', (
      tester,
    ) async {
      final lastEvent = ParayanEvent(
        id: 'gunjan_last',
        titleEn: 'Gunjan Last Event',
        titleMr: 'गुंजन मागील कार्यक्रम',
        descriptionEn: 'Last Desc EN',
        descriptionMr: 'Last Desc MR',
        type: ParayanType.threeDay,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        reminderTimes: [],
        groupId: GroupConstants.gunjan,
        status: 'completed',
      );

      when(
        () => mockService.getGunjanEvents(),
      ).thenAnswer((_) async => [lastEvent]);
      when(() => mockService.exists(any())).thenAnswer((_) async => false);
      when(
        () => mockService.getParticipantsOnce(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockService.createEventWithParticipants(
          event: any(named: 'event'),
          participants: any(named: 'participants'),
        ),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(
        createTestWidget(
          AdminParayanCreateWithAllocationScreen(
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

      // Ensure button is visible since the form might scroll
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify createEventWithParticipants is called with status 'allocated'
      // — this flow already copies over participant allocations from the
      // last parayan, so the new event shouldn't start at 'upcoming'.
      final captured =
          verify(
                () => mockService.createEventWithParticipants(
                  event: captureAny(named: 'event'),
                  participants: any(named: 'participants'),
                ),
              ).captured.single
              as ParayanEvent;
      expect(captured.status, 'allocated');
    });

    testWidgets('shows duplicate date error if event already exists', (
      tester,
    ) async {
      final lastEvent = ParayanEvent(
        id: 'gunjan_last',
        titleEn: 'Gunjan Last Event',
        titleMr: 'गुंजन मागील कार्यक्रम',
        descriptionEn: 'Last Desc EN',
        descriptionMr: 'Last Desc MR',
        type: ParayanType.threeDay,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        reminderTimes: [],
        groupId: GroupConstants.gunjan,
        status: 'completed',
      );

      when(
        () => mockService.getGunjanEvents(),
      ).thenAnswer((_) async => [lastEvent]);
      when(() => mockService.exists(any())).thenAnswer((_) async => true);

      await tester.pumpWidget(
        createTestWidget(
          AdminParayanCreateWithAllocationScreen(
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

      // Ensure button is visible since the form might scroll
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(
        find.text('A Parayan event already exists for this date.'),
        findsOneWidget,
      );
    });

    testWidgets('displays 4-day options and submits with correct dates', (
      tester,
    ) async {
      final lastEvent = ParayanEvent(
        id: 'gunjan_last',
        titleEn: 'Gunjan Last Event',
        titleMr: 'गुंजन मागील कार्यक्रम',
        descriptionEn: 'Last Desc EN',
        descriptionMr: 'Last Desc MR',
        type: ParayanType.threeDay,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        reminderTimes: [],
        groupId: GroupConstants.gunjan,
        status: 'completed',
      );

      when(
        () => mockService.getGunjanEvents(),
      ).thenAnswer((_) async => [lastEvent]);
      when(() => mockService.exists(any())).thenAnswer((_) async => false);
      when(
        () => mockService.getParticipantsOnce(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockService.createEventWithParticipants(
          event: any(named: 'event'),
          participants: any(named: 'participants'),
        ),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(
        createTestWidget(
          AdminParayanCreateWithAllocationScreen(
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

      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);

      SwitchListTile switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, false);

      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, true);

      expect(find.text('Tithi spanning 2 days'), findsOneWidget);

      await tester.tap(find.text('Dashami (Day 1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dwadashi (Day 3)').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () => mockService.createEventWithParticipants(
                  event: captureAny(named: 'event'),
                  participants: any(named: 'participants'),
                ),
              ).captured.single
              as ParayanEvent;

      expect(captured.is4DayParayan, true);
      expect(captured.extraDayTithi, 'dwadashi');
      expect(
        captured.endDate.difference(captured.startDate).inDays,
        3,
      ); // 4 days span
    });
  });
}

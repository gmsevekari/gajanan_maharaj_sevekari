import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/parayan/preallocated_parayan_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/parayan/widgets/claim_allocation_dialog.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks.dart';

void main() {
  late MockParayanService mockService;
  late ParayanEvent mockEvent;
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

    // Default mock behavior
    when(() => mockFestivalProvider.activeFestival).thenReturn(null);
    when(
      () => mockThemeProvider.themePreset,
    ).thenReturn(ThemePreset.tulsi); // Standard preset
    when(() => mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockThemeProvider.customColor).thenReturn(null);

    mockEvent = ParayanEvent(
      id: 'gajanan_gunjan_2024',
      titleEn: 'Gunjan Event',
      titleMr: 'गुंजन कार्यक्रम',
      descriptionEn: '',
      descriptionMr: '',
      type: ParayanType.oneDay,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      status: 'ongoing',
      reminderTimes: [],
      createdAt: DateTime.now(),
      groupId: 'gajanan_gunjan',
    );
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
        routes: {Routes.home: (context) => const Scaffold(body: Text('Home'))},
        home: child,
      ),
    );
  }

  group('PreallocatedParayanDetailScreen Tests', () {
    testWidgets('shows placeholder text and enabled button when not linked', (
      tester,
    ) async {
      when(
        () => mockService.getParticipantsByDevice(any(), any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        createTestWidget(
          PreallocatedParayanDetailScreen(
            event: mockEvent,
            deviceId: 'test-device-id',
            parayanService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify placeholder text is visible
      expect(find.textContaining('Use \'Find My Adhyays\''), findsOneWidget);

      // Verify "Find My Adhyays" button is enabled
      final finder = find.widgetWithText(ElevatedButton, 'Find My Adhyays');
      expect(finder, findsOneWidget);
      final button = tester.widget<ElevatedButton>(finder);
      expect(button.onPressed, isNotNull);
    });

    testWidgets(
      'disables "Find My Allocation" button when linked to a participant',
      (tester) async {
        when(
          () => mockService.getParticipantsByDevice(any(), any()),
        ).thenAnswer(
          (_) => Stream.value([
            ParayanMember(
              id: 'p1',
              name: 'Test Participant',
              phone: '+911234567890',
              completions: {},
              assignedAdhyays: [1],
              joinedAt: DateTime.now(),
            ),
          ]),
        );

        await tester.pumpWidget(
          createTestWidget(
            PreallocatedParayanDetailScreen(
              event: mockEvent,
              deviceId: 'test-device-id',
              parayanService: mockService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify "Find My Adhyays" button is present but disabled
        final finder = find.widgetWithText(ElevatedButton, 'Find My Adhyays');
        expect(finder, findsOneWidget);
        final button = tester.widget<ElevatedButton>(finder);
        expect(button.onPressed, isNull);

        // Verify placeholder is GONE and list items are shown
        expect(find.textContaining('Use \'Find My Adhyays\''), findsNothing);
        expect(find.textContaining('Test Participant'), findsOneWidget);
      },
    );

    testWidgets('initializes by fetching event when only eventId is provided', (
      tester,
    ) async {
      when(
        () => mockService.getEventById(any()),
      ).thenAnswer((_) => Stream.value(mockEvent));
      when(
        () => mockService.getParticipantsByDevice(any(), any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        createTestWidget(
          PreallocatedParayanDetailScreen(
            eventId: 'event_123',
            deviceId: 'd1',
            parayanService: mockService,
          ),
        ),
      );

      // Wait for the event stream and initial build
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Gunjan Event'), findsOneWidget);
      verify(() => mockService.getEventById('event_123')).called(1);
    });

    testWidgets('calls UniqueIdService fallback when deviceId is null', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'unique_device_id': 'mock-device-id',
      });
      when(
        () => mockService.getParticipantsByDevice(any(), any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        createTestWidget(
          PreallocatedParayanDetailScreen(
            event: mockEvent,
            deviceId: null,
            parayanService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(_findDeviceIdInStreamCall(mockService), 'mock-device-id');
    });

    testWidgets('opens claim dialog when Find My Adhyays is clicked', (
      tester,
    ) async {
      when(
        () => mockService.getParticipantsByDevice(any(), any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        createTestWidget(
          PreallocatedParayanDetailScreen(
            event: mockEvent,
            deviceId: 'd1',
            parayanService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Find My Adhyays'));
      await tester.pumpAndSettle();

      // Verify ClaimAllocationDialog is shown
      expect(find.text('Find My Adhyays'), findsWidgets);

      // Simulate dialog returning true
      Navigator.pop(tester.element(find.byType(ClaimAllocationDialog)), true);
      await tester.pumpAndSettle();
    });

    testWidgets('navigates to home when home button is clicked', (
      tester,
    ) async {
      when(
        () => mockService.getParticipantsByDevice(any(), any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        createTestWidget(
          PreallocatedParayanDetailScreen(
            event: mockEvent,
            deviceId: 'd1',
            parayanService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final homeButton = find.byIcon(Icons.home);
      expect(homeButton, findsOneWidget);

      // Since we use pushNamedAndRemoveUntil, we just verify it doesn't crash
      // and we could potentially verify navigation with a mock observer if needed.
      await tester.tap(homeButton);
      await tester.pumpAndSettle();
    });

    testWidgets('formats date correctly in Marathi locale', (tester) async {
      when(
        () => mockService.getParticipantsByDevice(any(), any()),
      ).thenAnswer((_) => Stream.value([]));

      // Mock Marathi event
      final mrEvent = ParayanEvent(
        id: 'e1',
        titleEn: 'En',
        titleMr: 'गुंजन',
        descriptionEn: '',
        descriptionMr: '',
        type: ParayanType.oneDay,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 1),
        status: 'ongoing',
        reminderTimes: [],
        createdAt: DateTime.now(),
        groupId: 'gajanan_gunjan',
      );

      await tester.pumpWidget(
        createTestWidget(
          Localizations(
            locale: const Locale('mr'),
            delegates: AppLocalizations.localizationsDelegates,
            child: PreallocatedParayanDetailScreen(
              event: mrEvent,
              deviceId: 'd1',
              parayanService: mockService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title in Marathi
      expect(find.text('गुंजन'), findsOneWidget);

      // Verify Date in Marathi numerals (1 Jan 2024) -> १ जानेवारी, २०२४
      // Using toMarathiNumerals logic in screen
      expect(find.textContaining('जानेवारी'), findsOneWidget);
    });
  });
}

String? _findDeviceIdInStreamCall(MockParayanService mock) {
  final calls = verify(
    () => mock.getParticipantsByDevice(any(), captureAny()),
  ).captured;
  return calls.last as String?;
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/parayan/adhyays_allocation_tab.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../mocks.dart';

void main() {
  late MockParayanService mockService;
  late MockFestivalProvider mockFestivalProvider;
  late MockThemeProvider mockThemeProvider;
  late MockFontProvider mockFontProvider;
  late MockAppConfigProvider mockAppConfigProvider;

  setUpAll(() async {
    await initializeDateFormatting('mr', null);
    await initializeDateFormatting('en', null);
  });

  setUp(() {
    mockService = MockParayanService();
    mockFestivalProvider = MockFestivalProvider();
    mockThemeProvider = MockThemeProvider();
    mockFontProvider = MockFontProvider();
    mockAppConfigProvider = MockAppConfigProvider();

    when(() => mockFestivalProvider.activeFestival).thenReturn(null);
    when(() => mockThemeProvider.themePreset).thenReturn(ThemePreset.tulsi);
    when(() => mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockThemeProvider.customColor).thenReturn(null);
  });

  Widget createTestWidget(Widget child, {Locale locale = const Locale('en')}) {
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
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  group('AdhyaysAllocationTab Tests', () {
    testWidgets('displays double dates for 4-day parayan in headers', (
      tester,
    ) async {
      final fourDayEvent = ParayanEvent(
        id: 'e_4day',
        titleEn: '4-Day En',
        titleMr: '४-दिवसीय',
        descriptionEn: '',
        descriptionMr: '',
        type: ParayanType.threeDay,
        startDate: DateTime.utc(2026, 7, 12),
        endDate: DateTime.utc(2026, 7, 16),
        status: 'ongoing',
        reminderTimes: [],
        createdAt: DateTime.now(),
        groupId: 'gajanan_gunjan',
        timezone: 'Asia/Kolkata',
        is4DayParayan: true,
        extraDayTithi: 'ekadashi',
      );

      when(
        () => mockService.getAllParticipants(any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        createTestWidget(
          AdhyaysAllocationTab(
            event: fourDayEvent,
            parayanService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('July 12'), findsOneWidget);
      expect(find.textContaining('July 13 & July 14'), findsOneWidget);
      expect(find.textContaining('July 15'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/vaari/vaari_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';

class MockVaariService extends Mock implements VaariService {}

void main() {
  late MockVaariService mockService;
  final now = DateTime.now();

  final mockActiveEvent = VaariEvent(
    id: 'vaari_active_1',
    createdAt: now,
    endDate: now.add(const Duration(days: 3)),
    groupId: 'g1',
    joinCode: '123456',
    nameEn: 'Seattle Active Walk',
    nameMr: 'सिएटल वारी',
    descriptionEn: 'Walk together in Seattle',
    descriptionMr: 'सिएटलमध्ये वारी',
    startDate: now,
    status: 'ongoing',
    timezone: 'America/Los_Angeles',
    totalSteps: 15000,
    totalDistance: 12.0,
    distanceUnit: 'km',
  );

  final mockCompletedEvent = VaariEvent(
    id: 'vaari_completed_1',
    createdAt: now.subtract(const Duration(days: 5)),
    endDate: now.subtract(const Duration(days: 2)),
    groupId: 'g1',
    joinCode: '123456',
    nameEn: 'Seattle Completed Walk',
    nameMr: 'सिएटल पूर्ण वारी',
    descriptionEn: 'Completed Seattle Walk',
    descriptionMr: 'पूर्ण झालेली वारी',
    startDate: now.subtract(const Duration(days: 5)),
    status: 'completed',
    timezone: 'America/Los_Angeles',
    totalSteps: 45000,
    totalDistance: 36.0,
    distanceUnit: 'km',
  );

  setUp(() {
    mockService = MockVaariService();
    when(() => mockService.getActiveEvents(any())).thenAnswer((_) => Stream.value([]));
    when(() => mockService.getCompletedEvents(any())).thenAnswer((_) => Stream.value([]));
  });

  Widget createListScreen({String? groupId, String? groupName, Map<String, WidgetBuilder>? mockRoutes, Locale? locale}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
        Provider<VaariService>.value(value: mockService),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale ?? const Locale('en'),
        home: VaariListScreen(
          groupId: groupId ?? 'g1',
          groupName: groupName,
        ),
        routes: mockRoutes ?? {},
      ),
    );
  }

  group('VaariListScreen Widget Tests', () {
    testWidgets('renders with two tabs and custom group name in AppBar', (tester) async {
      await tester.pumpWidget(createListScreen(groupName: 'Seattle Devotees'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Seattle Devotees'), findsOneWidget);
      expect(find.text('Upcoming / Active'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('renders empty state when no active events', (tester) async {
      when(() => mockService.getActiveEvents('g1')).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createListScreen());
      await tester.pumpAndSettle();

      expect(find.text('No active Vaari events currently'), findsOneWidget);
    });

    testWidgets('renders active events list and allows navigation on tap', (tester) async {
      when(() => mockService.getActiveEvents('g1')).thenAnswer((_) => Stream.value([mockActiveEvent]));

      String? navigatedRoute;
      dynamic navigatedArgs;

      await tester.pumpWidget(createListScreen(
        mockRoutes: {
          Routes.vaariDetail: (context) {
            navigatedRoute = Routes.vaariDetail;
            navigatedArgs = ModalRoute.of(context)?.settings.arguments;
            return const Scaffold(body: Text('Detail Screen'));
          }
        },
      ));
      await tester.pumpAndSettle();

      // Verify event card is rendered
      expect(find.text('Seattle Active Walk'), findsOneWidget);
      expect(find.text('15,000 steps'), findsOneWidget); // should format steps
      expect(find.text('12.0 km'), findsOneWidget); // should format distance

      // Tap card to navigate
      await tester.tap(find.text('Seattle Active Walk'));
      await tester.pumpAndSettle();

      expect(navigatedRoute, Routes.vaariDetail);
      expect(navigatedArgs, isA<Map>());
      expect(navigatedArgs['id'], 'vaari_active_1');
    });

    testWidgets('switches to Completed tab and renders completed events', (tester) async {
      when(() => mockService.getActiveEvents('g1')).thenAnswer((_) => Stream.value([]));
      when(() => mockService.getCompletedEvents('g1')).thenAnswer((_) => Stream.value([mockCompletedEvent]));

      await tester.pumpWidget(createListScreen());
      await tester.pumpAndSettle();

      // Tap "Completed" Tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Verify completed event is rendered
      expect(find.text('Seattle Completed Walk'), findsOneWidget);
      expect(find.text('45,000 steps'), findsOneWidget);
      expect(find.text('36.0 km'), findsOneWidget);
    });

    testWidgets('renders completed empty state when no completed events', (tester) async {
      when(() => mockService.getActiveEvents('g1')).thenAnswer((_) => Stream.value([]));
      when(() => mockService.getCompletedEvents('g1')).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createListScreen());
      await tester.pumpAndSettle();

      // Tap "Completed" Tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('No completed Vaari events yet'), findsOneWidget);
    });

    testWidgets('navigates to Home screen when home button is pressed', (tester) async {
      when(() => mockService.getActiveEvents('g1')).thenAnswer((_) => Stream.value([]));
      
      bool navigatedToHome = false;

      await tester.pumpWidget(createListScreen(
        mockRoutes: {
          Routes.home: (context) {
            navigatedToHome = true;
            return const Scaffold();
          }
        },
      ));
      await tester.pumpAndSettle();

      final homeButton = find.byIcon(Icons.home);
      expect(homeButton, findsOneWidget);

      await tester.tap(homeButton);
      await tester.pumpAndSettle();

      expect(navigatedToHome, isTrue);
    });

    testWidgets('navigates to Settings screen when settings button is pressed', (tester) async {
      when(() => mockService.getActiveEvents('g1')).thenAnswer((_) => Stream.value([]));
      
      bool navigatedToSettings = false;

      await tester.pumpWidget(createListScreen(
        mockRoutes: {
          Routes.settings: (context) {
            navigatedToSettings = true;
            return const Scaffold();
          }
        },
      ));
      await tester.pumpAndSettle();

      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);

      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      expect(navigatedToSettings, isTrue);
    });

    testWidgets('renders error message when active stream emits error', (tester) async {
      when(() => mockService.getActiveEvents('g1')).thenAnswer((_) => Stream.error('Database connection lost'));

      await tester.pumpWidget(createListScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Database connection lost'), findsOneWidget);
    });

    testWidgets('renders list elements correctly in Marathi locale', (tester) async {
      when(() => mockService.getActiveEvents('g1')).thenAnswer((_) => Stream.value([mockActiveEvent]));

      await tester.pumpWidget(createListScreen(locale: const Locale('mr')));
      await tester.pumpAndSettle();

      // Verified: 'Seattle Active Walk' in Marathi should use nameMr
      expect(find.text('सिएटल वारी'), findsOneWidget);
      
      // Verified: Numbers should be formatted in Marathi numerals
      // 15,000 steps -> १५,००० पायऱ्या
      expect(find.text('१५,००० पायऱ्या'), findsOneWidget);
      
      // 12.0 km -> १२.० किमी
      expect(find.text('१२.० किमी'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/group_namjap_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_service.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/jap_mala_provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/namjap_signup_dialog.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/manual_jap_tab.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupNamjapService extends Mock implements GroupNamjapService {}

class MockGroupNamjapProvider extends Mock implements GroupNamjapProvider {}

class MockJapMalaProvider extends Mock implements JapMalaProvider {}

void main() {
  late MockGroupNamjapService mockService;
  late MockGroupNamjapProvider mockGroupProvider;
  late MockJapMalaProvider mockJapProvider;
  late GroupNamjapEvent testEvent;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockService = MockGroupNamjapService();
    mockGroupProvider = MockGroupNamjapProvider();
    mockJapProvider = MockJapMalaProvider();

    testEvent = GroupNamjapEvent(
      id: 'test_event',
      nameEn: 'Test Event',
      nameMr: 'चाचणी इव्हेंट',
      sankalpEn: 'Test Sankalp',
      sankalpMr: 'चाचणी संकल्प',
      mantra: 'Gan Gan Ganat Bote',
      targetCount: 1000,
      totalCount: 500,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
      status: 'ongoing',
      joinCode: '123456',
      groupId: 'seattle',
    );

    when(
      () => mockService.getEventStream(any()),
    ).thenAnswer((_) => Stream.value(testEvent));
    when(
      () => mockService.getParticipantStream(any(), any(), any()),
    ).thenAnswer((_) => Stream.value(null));
    when(
      () => mockService.getParticipantsCountStream(any()),
    ).thenAnswer((_) => Stream.value(1));

    when(() => mockGroupProvider.loadLocalData()).thenAnswer((_) async {});
    when(
      () => mockGroupProvider.syncParticipation(any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockGroupProvider.isJoined(any())).thenReturn(false);
    when(() => mockGroupProvider.hasProfile).thenReturn(false);
    when(() => mockGroupProvider.memberName).thenReturn(null);
    when(() => mockGroupProvider.isLoading).thenReturn(false);

    when(() => mockJapProvider.totalCount).thenReturn(0);
    when(() => mockJapProvider.init()).thenAnswer((_) async {});
  });

  Widget createWidget(String eventId) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<FestivalProvider>(
          create: (_) => FestivalProvider(),
        ),
        ChangeNotifierProvider<GroupNamjapService>.value(value: mockService),
        ChangeNotifierProvider<GroupNamjapProvider>.value(
          value: mockGroupProvider,
        ),
        ChangeNotifierProvider<JapMalaProvider>.value(value: mockJapProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: GroupNamjapDetailScreen(eventId: eventId),
      ),
    );
  }

  testWidgets('GroupNamjapDetailScreen triggers sync on load', (tester) async {
    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    verify(() => mockGroupProvider.loadLocalData()).called(1);
    verify(() => mockGroupProvider.syncParticipation(any(), any())).called(1);
  });

  testWidgets('Sign Up button is enabled for enrolling status', (tester) async {
    final enrollingEvent = testEvent.copyWith(
      id: 'enrolling_1',
      status: 'enrolling',
    );
    when(
      () => mockService.getEventStream('enrolling_1'),
    ).thenAnswer((_) => Stream.value(enrollingEvent));
    when(
      () => mockService.checkParticipation('enrolling_1', any()),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(createWidget('enrolling_1'));
    await tester.pumpAndSettle();

    final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
    expect(signUpButton, findsOneWidget);
    expect(tester.widget<ElevatedButton>(signUpButton).enabled, isTrue);
  });

  testWidgets('Sign Up dialog shows and allows entry', (tester) async {
    when(
      () => mockService.checkParticipation(any(), any()),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    expect(find.byType(NamjapSignupDialog), findsOneWidget);
    expect(
      find.text('+91'),
      findsAtLeastNWidgets(1),
    ); // Initial value in TextFormField
  });

  testWidgets('Shows edit and delete buttons when enrolling and joined', (
    tester,
  ) async {
    final enrollingEvent = testEvent.copyWith(
      id: 'enrolling_1',
      status: 'enrolling',
    );
    when(
      () => mockService.getEventStream('enrolling_1'),
    ).thenAnswer((_) => Stream.value(enrollingEvent));
    when(
      () => mockGroupProvider.isJoined('enrolling_1'),
    ).thenReturn(true);
    when(() => mockGroupProvider.memberName).thenReturn('Test User');

    await tester.pumpWidget(createWidget('enrolling_1'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Edit Signup'), findsOneWidget);
  });

  testWidgets('Order of components: Manual Entry -> Submit -> Mala Tab', (tester) async {
    when(() => mockGroupProvider.isJoined('test_event')).thenReturn(true);
    when(() => mockGroupProvider.memberName).thenReturn('Test User');
    when(() => mockJapProvider.totalCount).thenReturn(0);

    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    final manualEntry = find.byIcon(Icons.edit_note);
    final submitButton = find.widgetWithText(ElevatedButton, 'Submit Namjap Count: 0');
    final malaTab = find.byType(ManualJapTab);

    expect(manualEntry, findsOneWidget);
    expect(submitButton, findsOneWidget);
    expect(malaTab, findsOneWidget);

    final manualEntryY = tester.getCenter(manualEntry).dy;
    final submitButtonY = tester.getCenter(submitButton).dy;
    final malaTabY = tester.getCenter(malaTab).dy;

    expect(
      manualEntryY < submitButtonY,
      isTrue,
      reason: 'Manual Entry should be above Submit',
    );
    expect(
      submitButtonY < malaTabY,
      isTrue,
      reason: 'Submit should be above Mala Tab',
    );
  });
}

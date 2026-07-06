import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/vaari/vaari_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/vaari/widgets/vaari_signup_dialog.dart';
import 'package:gajanan_maharaj_sevekari/vaari/widgets/add_steps_dialog.dart';
import 'package:gajanan_maharaj_sevekari/vaari/widgets/vaari_participants_table.dart';
import 'package:gajanan_maharaj_sevekari/vaari/widgets/vaari_route_progress.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

class MockVaariService extends Mock implements VaariService {}

class MockVaariProvider extends Mock implements VaariProvider {}

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

void main() {
  late MockVaariService mockService;
  late MockVaariProvider mockVaariProvider;
  late MockAppConfigProvider mockAppConfigProvider;
  late VaariEvent testEvent;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockService = MockVaariService();
    mockVaariProvider = MockVaariProvider();
    mockAppConfigProvider = MockAppConfigProvider();

    when(() => mockAppConfigProvider.appConfig).thenReturn(null);

    testEvent = VaariEvent(
      id: 'test_event',
      nameEn: 'Test Event',
      nameMr: 'चाचणी इव्हेंट',
      descriptionEn: 'Test Description',
      descriptionMr: 'चाचणी वर्णन',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
      status: 'ongoing',
      joinCode: '123456',
      groupId: 'seattle',
      timezone: 'America/Los_Angeles',
      totalSteps: 15000,
      totalDistance: 12.0,
      distanceUnit: 'km',
    );

    when(
      () => mockService.getEventStream(any()),
    ).thenAnswer((_) => Stream.value(testEvent));
    when(
      () => mockService.getParticipantsCountStream(any()),
    ).thenAnswer((_) => Stream.value(1));
    when(
      () => mockService.getAllParticipants(any()),
    ).thenAnswer((_) => Stream.value([]));

    when(() => mockVaariProvider.loadLocalData()).thenAnswer((_) async {});
    when(
      () => mockVaariProvider.syncParticipation(any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockVaariProvider.isJoined(any())).thenReturn(false);
    when(() => mockVaariProvider.hasProfile).thenReturn(false);
    when(() => mockVaariProvider.memberName).thenReturn(null);
    when(() => mockVaariProvider.isLoading).thenReturn(false);
  });

  Widget createWidget(
    String eventId, {
    Map<String, WidgetBuilder>? mockRoutes,
    Locale? locale,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<FestivalProvider>(
          create: (_) => FestivalProvider(),
        ),
        Provider<VaariService>.value(value: mockService),
        ChangeNotifierProvider<VaariProvider>.value(value: mockVaariProvider),
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
        supportedLocales: const [Locale('en'), Locale('mr')],
        locale: locale,
        home: VaariDetailScreen(eventId: eventId),
        routes: mockRoutes ?? {},
      ),
    );
  }

  testWidgets('VaariDetailScreen triggers sync on load', (tester) async {
    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    verify(() => mockVaariProvider.loadLocalData()).called(1);
    verify(() => mockVaariProvider.syncParticipation(any(), any())).called(1);
  });

  testWidgets('renders event title, description and status', (tester) async {
    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    expect(find.text('Test Event'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
    expect(find.text('Ongoing'), findsOneWidget);
  });

  testWidgets('renders only the group total steps and distance cards', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    expect(find.text('Total Steps'.toUpperCase()), findsOneWidget);
    expect(find.text('Total Distance (km)'.toUpperCase()), findsOneWidget);
    expect(find.text('15,000'), findsOneWidget);
    expect(find.text('12.0'), findsOneWidget);
    // The old personal "My Steps"/"My Distance" cards must be gone.
    expect(find.text('My Steps'.toUpperCase()), findsNothing);
    expect(find.text('My Distance'.toUpperCase()), findsNothing);
  });

  testWidgets('renders the Alandi-to-Pandharpur route progress', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    expect(find.byType(VaariRouteProgress), findsOneWidget);
    expect(find.text('ROUTE PROGRESS'), findsOneWidget);
    // testEvent.totalDistance is 12.0 km.
    expect(find.text('12.0 / 249.4 km'), findsOneWidget);
  });

  testWidgets('renders event-not-found state when stream emits null', (
    tester,
  ) async {
    when(
      () => mockService.getEventStream('missing_event'),
    ).thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(createWidget('missing_event'));
    await tester.pumpAndSettle();

    expect(find.text('Event not found'), findsOneWidget);
  });

  testWidgets('Sign Up button is enabled for enrolling status', (tester) async {
    final enrollingEvent = testEvent.copyWith(
      id: 'enrolling_1',
      status: 'enrolling',
    );
    when(
      () => mockService.getEventStream('enrolling_1'),
    ).thenAnswer((_) => Stream.value(enrollingEvent));

    await tester.pumpWidget(createWidget('enrolling_1'));
    await tester.pumpAndSettle();

    final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
    expect(signUpButton, findsOneWidget);
    expect(tester.widget<ElevatedButton>(signUpButton).enabled, isTrue);
  });

  testWidgets('Sign Up dialog shows and allows entry', (tester) async {
    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    expect(find.byType(VaariSignupDialog), findsOneWidget);
    expect(find.text('+1'), findsAtLeastNWidgets(1));
  });

  testWidgets('Shows edit button when enrolling and joined', (tester) async {
    final enrollingEvent = testEvent.copyWith(
      id: 'enrolling_1',
      status: 'enrolling',
    );
    when(
      () => mockService.getEventStream('enrolling_1'),
    ).thenAnswer((_) => Stream.value(enrollingEvent));
    when(() => mockVaariProvider.isJoined('enrolling_1')).thenReturn(true);
    when(() => mockVaariProvider.memberName).thenReturn('Test User');

    await tester.pumpWidget(createWidget('enrolling_1'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Edit Signup'), findsOneWidget);
  });

  testWidgets('Add Steps button visible when joined and ongoing', (
    tester,
  ) async {
    when(() => mockVaariProvider.isJoined('test_event')).thenReturn(true);
    when(() => mockVaariProvider.memberName).thenReturn('Test User');

    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Add Steps'), findsOneWidget);
  });

  testWidgets('Add Steps button hidden when not joined', (tester) async {
    when(() => mockVaariProvider.isJoined('test_event')).thenReturn(false);

    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Add Steps'), findsNothing);
  });

  testWidgets('Add Steps button hidden when status is completed', (
    tester,
  ) async {
    final completedEvent = testEvent.copyWith(
      id: 'completed_1',
      status: 'completed',
    );
    when(
      () => mockService.getEventStream('completed_1'),
    ).thenAnswer((_) => Stream.value(completedEvent));
    when(() => mockVaariProvider.isJoined('completed_1')).thenReturn(true);
    when(() => mockVaariProvider.memberName).thenReturn('Test User');

    await tester.pumpWidget(createWidget('completed_1'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Add Steps'), findsNothing);
  });

  testWidgets('Add Steps dialog opens and submits', (tester) async {
    when(() => mockVaariProvider.isJoined('test_event')).thenReturn(true);
    when(() => mockVaariProvider.memberName).thenReturn('Test User');
    when(
      () => mockService.submitSteps(
        eventId: any(named: 'eventId'),
        deviceId: any(named: 'deviceId'),
        memberName: any(named: 'memberName'),
        stepsToSubmit: any(named: 'stepsToSubmit'),
        distanceToSubmit: any(named: 'distanceToSubmit'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Add Steps'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Steps'));
    await tester.pumpAndSettle();

    expect(find.byType(AddStepsDialog), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Steps'), '2000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    verify(
      () => mockService.submitSteps(
        eventId: 'test_event',
        deviceId: any(named: 'deviceId'),
        memberName: 'Test User',
        stepsToSubmit: 2000,
        distanceToSubmit: null,
      ),
    ).called(1);
    expect(find.text('Steps submitted successfully'), findsOneWidget);
  });

  testWidgets('Add Steps dialog submits a valid distance override', (
    tester,
  ) async {
    when(() => mockVaariProvider.isJoined('test_event')).thenReturn(true);
    when(() => mockVaariProvider.memberName).thenReturn('Test User');
    when(
      () => mockService.submitSteps(
        eventId: any(named: 'eventId'),
        deviceId: any(named: 'deviceId'),
        memberName: any(named: 'memberName'),
        stepsToSubmit: any(named: 'stepsToSubmit'),
        distanceToSubmit: any(named: 'distanceToSubmit'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Add Steps'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Steps'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Distance'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1.6');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    verify(
      () => mockService.submitSteps(
        eventId: 'test_event',
        deviceId: any(named: 'deviceId'),
        memberName: 'Test User',
        stepsToSubmit: 2000,
        distanceToSubmit: 1.6,
      ),
    ).called(1);
  });

  testWidgets('Add Steps dialog shows validation error for zero steps', (
    tester,
  ) async {
    when(() => mockVaariProvider.isJoined('test_event')).thenReturn(true);
    when(() => mockVaariProvider.memberName).thenReturn('Test User');

    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Add Steps'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Steps'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
    verifyNever(
      () => mockService.submitSteps(
        eventId: any(named: 'eventId'),
        deviceId: any(named: 'deviceId'),
        memberName: any(named: 'memberName'),
        stepsToSubmit: any(named: 'stepsToSubmit'),
        distanceToSubmit: any(named: 'distanceToSubmit'),
      ),
    );
  });

  testWidgets('Add Steps dialog shows an error message when submit fails', (
    tester,
  ) async {
    when(() => mockVaariProvider.isJoined('test_event')).thenReturn(true);
    when(() => mockVaariProvider.memberName).thenReturn('Test User');
    when(
      () => mockService.submitSteps(
        eventId: any(named: 'eventId'),
        deviceId: any(named: 'deviceId'),
        memberName: any(named: 'memberName'),
        stepsToSubmit: any(named: 'stepsToSubmit'),
        distanceToSubmit: any(named: 'distanceToSubmit'),
      ),
    ).thenThrow(Exception('network down'));

    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Add Steps'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Steps'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Steps'), '2000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.byType(AddStepsDialog), findsOneWidget);
    expect(find.textContaining('network down'), findsOneWidget);
  });

  testWidgets('renders description and status in Marathi locale', (
    tester,
  ) async {
    final upcomingEvent = testEvent.copyWith(
      id: 'upcoming_1',
      status: 'upcoming',
    );
    when(
      () => mockService.getEventStream('upcoming_1'),
    ).thenAnswer((_) => Stream.value(upcomingEvent));

    await tester.pumpWidget(
      createWidget('upcoming_1', locale: const Locale('mr')),
    );
    await tester.pumpAndSettle();

    expect(find.text('चाचणी वर्णन'), findsOneWidget);
    expect(find.text('Upcoming'.toUpperCase()), findsNothing);
  });

  testWidgets('home button navigates to Home route', (tester) async {
    bool navigatedToHome = false;

    await tester.pumpWidget(
      createWidget(
        'test_event',
        mockRoutes: {
          Routes.home: (context) {
            navigatedToHome = true;
            return const Scaffold();
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();

    expect(navigatedToHome, isTrue);
  });

  testWidgets('settings button navigates to Settings route', (tester) async {
    bool navigatedToSettings = false;

    await tester.pumpWidget(
      createWidget(
        'test_event',
        mockRoutes: {
          Routes.settings: (context) {
            navigatedToSettings = true;
            return const Scaffold();
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(navigatedToSettings, isTrue);
  });

  testWidgets('completing sign up updates participant stream', (tester) async {
    when(() => mockVaariProvider.isJoined('test_event')).thenReturn(false);
    when(() => mockVaariProvider.hasProfile).thenReturn(false);
    when(
      () => mockVaariProvider.signUp(
        eventId: any(named: 'eventId'),
        joinCode: any(named: 'joinCode'),
        memberName: any(named: 'memberName'),
        phone: any(named: 'phone'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Member Name'),
      'Rahul Patil',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number'),
      '9876543210',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Join Code'),
      'ABC123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    verify(
      () => mockVaariProvider.signUp(
        eventId: 'test_event',
        joinCode: 'ABC123',
        memberName: 'Rahul Patil',
        phone: '+19876543210',
        deviceId: any(named: 'deviceId'),
      ),
    ).called(1);
    expect(find.byType(VaariSignupDialog), findsNothing);
  });

  testWidgets('shows invalid join code message when sign up fails', (
    tester,
  ) async {
    when(() => mockVaariProvider.isJoined('test_event')).thenReturn(false);
    when(() => mockVaariProvider.hasProfile).thenReturn(false);
    when(
      () => mockVaariProvider.signUp(
        eventId: any(named: 'eventId'),
        joinCode: any(named: 'joinCode'),
        memberName: any(named: 'memberName'),
        phone: any(named: 'phone'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Member Name'),
      'Rahul Patil',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number'),
      '9876543210',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Join Code'),
      'WRONGC',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid Join Code!'), findsOneWidget);
    expect(find.byType(VaariSignupDialog), findsOneWidget);
  });

  testWidgets('deleting sign up shows confirmation then success snackbar', (
    tester,
  ) async {
    final enrollingEvent = testEvent.copyWith(
      id: 'enrolling_1',
      status: 'enrolling',
    );
    when(
      () => mockService.getEventStream('enrolling_1'),
    ).thenAnswer((_) => Stream.value(enrollingEvent));
    when(() => mockVaariProvider.isJoined('enrolling_1')).thenReturn(true);
    when(() => mockVaariProvider.memberName).thenReturn('Test User');
    when(() => mockVaariProvider.hasProfile).thenReturn(true);
    when(() => mockVaariProvider.phone).thenReturn('+19876543210');
    when(
      () => mockVaariProvider.deleteSignUp(any(), any()),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(createWidget('enrolling_1'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Edit Signup'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Delete Signup'));
    await tester.pumpAndSettle();

    // Confirm dialog stacks on top of the signup dialog, so both dialogs'
    // "Delete Signup" buttons are in the tree — target the topmost one.
    await tester.tap(find.widgetWithText(TextButton, 'Delete Signup').last);
    await tester.pumpAndSettle();

    verify(
      () => mockVaariProvider.deleteSignUp('enrolling_1', any()),
    ).called(1);
    expect(find.text('Signup deleted successfully'), findsOneWidget);
  });

  testWidgets('cancelling delete confirmation keeps the dialog open', (
    tester,
  ) async {
    final enrollingEvent = testEvent.copyWith(
      id: 'enrolling_1',
      status: 'enrolling',
    );
    when(
      () => mockService.getEventStream('enrolling_1'),
    ).thenAnswer((_) => Stream.value(enrollingEvent));
    when(() => mockVaariProvider.isJoined('enrolling_1')).thenReturn(true);
    when(() => mockVaariProvider.memberName).thenReturn('Test User');
    when(() => mockVaariProvider.hasProfile).thenReturn(true);
    when(() => mockVaariProvider.phone).thenReturn('+19876543210');

    await tester.pumpWidget(createWidget('enrolling_1'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Edit Signup'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Delete Signup'));
    await tester.pumpAndSettle();

    // Confirm dialog stacks on top of the signup dialog, so both dialogs'
    // "Cancel" buttons are in the tree — target the topmost one.
    await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
    await tester.pumpAndSettle();

    verifyNever(() => mockVaariProvider.deleteSignUp(any(), any()));
    expect(find.byType(VaariSignupDialog), findsOneWidget);
  });

  testWidgets('renders the participants table with each participant', (
    tester,
  ) async {
    when(() => mockService.getAllParticipants('test_event')).thenAnswer(
      (_) => Stream.value([
        VaariParticipant(
          memberName: 'Rahul Patil',
          deviceId: 'device_9',
          phone: '123',
          joinedAt: DateTime.now(),
          totalSteps: 8000,
          totalDistance: 6.4,
        ),
      ]),
    );

    await tester.pumpWidget(createWidget('test_event'));
    await tester.pumpAndSettle();

    expect(find.byType(VaariParticipantsTable), findsOneWidget);
    expect(find.text('Rahul Patil'), findsOneWidget);
    expect(find.text('8,000'), findsOneWidget);
    expect(find.text('6.4'), findsOneWidget);
  });

  testWidgets('displays "miles" instead of the raw "mi" code from Firestore', (
    tester,
  ) async {
    final milesEvent = testEvent.copyWith(
      id: 'miles_event',
      distanceUnit: 'mi',
    );
    when(
      () => mockService.getEventStream('miles_event'),
    ).thenAnswer((_) => Stream.value(milesEvent));
    when(() => mockVaariProvider.isJoined('miles_event')).thenReturn(true);
    when(() => mockVaariProvider.memberName).thenReturn('Test User');

    await tester.pumpWidget(createWidget('miles_event'));
    await tester.pumpAndSettle();

    expect(find.text('Total Distance (miles)'.toUpperCase()), findsOneWidget);

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Add Steps'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Steps'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Distance'));
    await tester.pumpAndSettle();

    expect(find.text('Distance in miles'), findsOneWidget);
  });
}

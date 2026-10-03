import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/signups/my_signups_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockSignupService extends Mock implements SignupService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;
  late String signupId;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
    final now = DateTime.now();
    signupId = await service.createSignup(
      Signup(
        titleEn: 'Sunday Prasad Seva',
        titleMr: 'रविवार प्रसाद सेवा',
        groupId: 'group_1',
        status: SignupStatus.published,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      ),
    );
  });

  Widget wrap(Widget child, {Locale? locale}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text(settings.name ?? '')),
            body: Text('Navigated to: ${settings.name}'),
          ),
        ),
        home: child,
      ),
    );
  }

  Future<String> addSlot({DateTime? date}) {
    return service.addSlot(
      signupId,
      SignupSlot(
        labelEn: 'Week 1',
        labelMr: 'आठवडा १',
        date: date,
        capacity: 3,
        sortOrder: 0,
        createdAt: DateTime.now(),
      ),
    );
  }

  testWidgets('shows the empty message on both tabs when there are no '
      'entries', (tester) async {
    await tester.pumpWidget(
      wrap(
        MySignupsScreen(
          signupId: signupId,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("You haven't signed up for anything yet"), findsOneWidget);
  });

  testWidgets('lists an entry for a future slot on the Upcoming tab', (
    tester,
  ) async {
    final slotId = await addSlot(
      date: DateTime.now().add(const Duration(days: 3)),
    );
    await service.claimSlot(
      signupId: signupId,
      slotId: slotId,
      name: 'Jane',
      deviceId: 'device_1',
    );

    await tester.pumpWidget(
      wrap(
        MySignupsScreen(
          signupId: signupId,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane'), findsOneWidget);
    expect(find.text('Week 1'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('lists an entry for a past slot on the Past tab, without a '
      'Cancel button', (tester) async {
    final slotId = await addSlot(
      date: DateTime.now().subtract(const Duration(days: 3)),
    );
    await service.claimSlot(
      signupId: signupId,
      slotId: slotId,
      name: 'Jane',
      deviceId: 'device_1',
    );

    await tester.pumpWidget(
      wrap(
        MySignupsScreen(
          signupId: signupId,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Upcoming tab (default) shows its own empty state; Past has the entry.
    expect(find.text("You haven't signed up for anything yet"), findsOneWidget);

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('Jane'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('treats an entry for a slot with no date as upcoming', (
    tester,
  ) async {
    final slotId = await addSlot();
    await service.claimSlot(
      signupId: signupId,
      slotId: slotId,
      name: 'Jane',
      deviceId: 'device_1',
    );

    await tester.pumpWidget(
      wrap(
        MySignupsScreen(
          signupId: signupId,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('cancelling an upcoming entry removes it after confirmation', (
    tester,
  ) async {
    final slotId = await addSlot(
      date: DateTime.now().add(const Duration(days: 3)),
    );
    await service.claimSlot(
      signupId: signupId,
      slotId: slotId,
      name: 'Jane',
      deviceId: 'device_1',
    );

    await tester.pumpWidget(
      wrap(
        MySignupsScreen(
          signupId: signupId,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel Signup?'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text("You haven't signed up for anything yet"), findsOneWidget);
    final entries = await service.getAllEntries(signupId).first;
    expect(entries, isEmpty);
  });

  testWidgets('declining the cancel confirmation keeps the entry', (
    tester,
  ) async {
    final slotId = await addSlot(
      date: DateTime.now().add(const Duration(days: 3)),
    );
    await service.claimSlot(
      signupId: signupId,
      slotId: slotId,
      name: 'Jane',
      deviceId: 'device_1',
    );

    await tester.pumpWidget(
      wrap(
        MySignupsScreen(
          signupId: signupId,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    expect(find.text('Jane'), findsOneWidget);
    final entries = await service.getAllEntries(signupId).first;
    expect(entries, hasLength(1));
  });

  testWidgets('shows an error snackbar when cancelling an entry fails', (
    tester,
  ) async {
    final entry = SignupEntry(
      id: 'entry_1',
      slotId: 'slot_1',
      name: 'Jane',
      deviceId: 'device_1',
      joinedAt: DateTime.now(),
    );
    final mockService = MockSignupService();
    when(
      () => mockService.getSlots(signupId),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => mockService.getEntriesByDevice(signupId, 'device_1'),
    ).thenAnswer((_) => Stream.value([entry]));
    when(
      () => mockService.cancelEntry(signupId, 'entry_1'),
    ).thenThrow(Exception('network error'));

    await tester.pumpWidget(
      wrap(
        MySignupsScreen(
          signupId: signupId,
          deviceId: 'device_1',
          signupService: mockService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(
      find.text('Failed to cancel signup. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping home icon navigates to home', (tester) async {
    await tester.pumpWidget(
      wrap(
        MySignupsScreen(
          signupId: signupId,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Navigated to: /home'), findsOneWidget);
  });

  testWidgets('tapping settings icon navigates to settings', (tester) async {
    await tester.pumpWidget(
      wrap(
        MySignupsScreen(
          signupId: signupId,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
          .at(1),
    );
    await tester.pumpAndSettle();

    expect(find.text('Navigated to: /settings'), findsOneWidget);
  });

  testWidgets('stays English under a Marathi app locale', (tester) async {
    await tester.pumpWidget(
      wrap(
        MySignupsScreen(
          signupId: signupId,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
        locale: const Locale('mr'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Signups'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.text("You haven't signed up for anything yet"), findsOneWidget);
  });

  testWidgets('tab labels contrast with the app bar so the selected tab is '
      'visible', (tester) async {
    await tester.pumpWidget(
      wrap(
        MySignupsScreen(
          signupId: signupId,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    final theme = AppTheme.lightTheme;
    final appBarColor = theme.appBarTheme.backgroundColor;
    expect(tabBar.labelColor, theme.colorScheme.onPrimary);
    expect(tabBar.labelColor, isNot(appBarColor));
    expect(tabBar.indicatorColor, theme.colorScheme.onPrimary);
  });
}

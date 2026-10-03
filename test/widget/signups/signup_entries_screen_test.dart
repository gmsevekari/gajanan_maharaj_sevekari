import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_entries_screen.dart';
import 'package:provider/provider.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;
  late String signupId;

  final future = DateTime(2099, 3, 15);
  final farFuture = DateTime(2099, 4, 1);
  final past = DateTime(2020, 1, 10);

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

  Widget screen({Locale? locale}) => wrap(
    SignupEntriesScreen(
      signupId: signupId,
      firestore: firestore,
      signupService: service,
    ),
    locale: locale,
  );

  Future<String> addSlot({
    String labelEn = 'Week 1',
    String labelMr = 'आठवडा १',
    DateTime? date,
    int capacity = 3,
  }) {
    return service.addSlot(
      signupId,
      SignupSlot(
        labelEn: labelEn,
        labelMr: labelMr,
        date: date,
        capacity: capacity,
        sortOrder: 0,
        createdAt: DateTime.now(),
      ),
    );
  }

  List<List<String?>> tableRows(WidgetTester tester) {
    final table = tester.widget<Table>(find.byType(Table));
    return table.children
        .skip(1) // header row
        .map(
          (row) => row.children
              .map((cell) => ((cell as Padding).child! as Text).data)
              .toList(),
        )
        .toList();
  }

  testWidgets('shows the empty message when there are no entries', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('Entries'), findsOneWidget);
    expect(find.text('No one has signed up yet'), findsOneWidget);
    expect(find.byType(Table), findsNothing);
  });

  testWidgets('lists upcoming entries sorted by date, then date ties by name', (
    tester,
  ) async {
    final slot1 = await addSlot(labelEn: 'Week 1', date: future, capacity: 3);
    final slot2 = await addSlot(
      labelEn: 'Week 2',
      date: farFuture,
      capacity: 2,
    );
    final slot3 = await addSlot(labelEn: 'Week 3', capacity: 1);
    final slot4 = await addSlot(labelEn: 'Week 4', date: future, capacity: 1);
    await service.claimSlot(signupId: signupId, slotId: slot1, name: 'Jane');
    await service.claimSlot(signupId: signupId, slotId: slot2, name: 'Amit');
    await service.claimSlot(signupId: signupId, slotId: slot3, name: 'Priya');
    await service.claimSlot(signupId: signupId, slotId: slot4, name: 'Anil');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    // Sorted by slot date (slot3's null date sorts last; slot1 and slot4 tie
    // on date and fall back to comparing names).
    expect(tableRows(tester), [
      ['March 15', 'Week 4', 'Anil', '0'], // 1 capacity - 1 claimed
      ['March 15', 'Week 1', 'Jane', '2'], // 3 capacity - 1 claimed
      ['April 1', 'Week 2', 'Amit', '1'], // 2 capacity - 1 claimed
      ['-', 'Week 3', 'Priya', '0'], // no date
    ]);
  });

  testWidgets('puts entries for past slots on the Past tab only', (
    tester,
  ) async {
    final pastSlot = await addSlot(labelEn: 'Old Week', date: past);
    final futureSlot = await addSlot(labelEn: 'New Week', date: future);
    await service.claimSlot(
      signupId: signupId,
      slotId: pastSlot,
      name: 'Past Person',
    );
    await service.claimSlot(
      signupId: signupId,
      slotId: futureSlot,
      name: 'Future Person',
    );

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('Future Person'), findsOneWidget);
    expect(find.text('Past Person'), findsNothing);

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('Past Person'), findsOneWidget);
    expect(find.text('Future Person'), findsNothing);
    expect(tableRows(tester), [
      ['January 10', 'Old Week', 'Past Person', '2'],
    ]);
  });

  testWidgets('shows the empty message on the Past tab when none are past', (
    tester,
  ) async {
    final slotId = await addSlot(date: future);
    await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('No one has signed up yet'), findsOneWidget);
  });

  testWidgets('shows a blank title and dash for an entry whose slot is gone', (
    tester,
  ) async {
    final slotId = await addSlot();
    await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Orphan');
    // Bypass SignupService.deleteSlot's claimed-entry guard to simulate an
    // entry left behind after its slot is gone some other way.
    await firestore
        .collection('signups')
        .doc(signupId)
        .collection('slots')
        .doc(slotId)
        .delete();

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(tableRows(tester), [
      ['-', '', 'Orphan', '-'],
    ]);
  });

  testWidgets(
    'shows the Marathi slot label but English UI and dates under mr',
    (tester) async {
      final slotId = await addSlot(date: future);
      await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

      await tester.pumpWidget(screen(locale: const Locale('mr')));
      await tester.pumpAndSettle();

      expect(find.text('Entries'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Available Slots'), findsOneWidget);
      expect(find.text('March 15'), findsOneWidget);
      expect(find.text('आठवडा १'), findsOneWidget);
    },
  );

  testWidgets('falls back to the other language when a slot label is blank', (
    tester,
  ) async {
    final slotId = await addSlot(labelEn: '', labelMr: 'आठवडा १');
    await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('आठवडा १'), findsOneWidget);
  });

  testWidgets('fits a narrow screen and wraps long text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final slotId = await addSlot(
      labelEn: 'A very long slot title that must wrap onto lines',
      date: future,
    );
    await service.claimSlot(
      signupId: signupId,
      slotId: slotId,
      name: 'A devotee with a remarkably long full name',
    );

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(Table)).width, lessThanOrEqualTo(360));
  });

  testWidgets('tab labels contrast with the app bar so the selected tab is '
      'visible', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    final theme = AppTheme.lightTheme;
    expect(tabBar.labelColor, theme.colorScheme.onPrimary);
    expect(tabBar.labelColor, isNot(theme.appBarTheme.backgroundColor));
    expect(tabBar.indicatorColor, theme.colorScheme.onPrimary);
  });

  testWidgets('tapping home icon navigates to home', (tester) async {
    await tester.pumpWidget(screen());
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
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
          .at(1),
    );
    await tester.pumpAndSettle();

    expect(find.text('Navigated to: /settings'), findsOneWidget);
  });

  testWidgets('does not switch tabs when the content is swiped', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    final controller = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    expect(controller.index, 0);
  });
}

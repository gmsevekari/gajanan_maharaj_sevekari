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
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
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
        startAt: date,
        endAt: date?.add(const Duration(hours: 23, minutes: 59)),
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

  testWidgets('does not switch tabs when the content is swiped', (
    tester,
  ) async {
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

    await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    final controller = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    expect(controller.index, 0);
  });

  group('which tab an entry is on follows the end of its slot', () {
    final now = DateTime.now();

    Future<void> pumpEntryFor(
      WidgetTester tester, {
      DateTime? startAt,
      DateTime? endAt,
    }) async {
      final slotId = await service.addSlot(
        signupId,
        SignupSlot(
          labelEn: 'Timed Week',
          labelMr: '',
          startAt: startAt,
          endAt: endAt,
          capacity: 3,
          sortOrder: 0,
          createdAt: DateTime.now(),
        ),
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
    }

    Future<void> expectOnUpcoming(WidgetTester tester) async {
      expect(find.text('Timed Week'), findsOneWidget);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Timed Week'), findsNothing);
    }

    Future<void> expectOnPast(WidgetTester tester) async {
      expect(find.text('Timed Week'), findsNothing);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Timed Week'), findsOneWidget);
    }

    testWidgets('a slot that started earlier today but ends later is '
        'upcoming', (tester) async {
      await pumpEntryFor(
        tester,
        startAt: now.subtract(const Duration(hours: 1)),
        endAt: now.add(const Duration(hours: 5)),
      );
      await expectOnUpcoming(tester);
    });

    testWidgets('a multi-day slot that is in progress is upcoming', (
      tester,
    ) async {
      await pumpEntryFor(
        tester,
        startAt: now.subtract(const Duration(days: 1)),
        endAt: now.add(const Duration(days: 2)),
      );
      await expectOnUpcoming(tester);
    });

    testWidgets('a slot that ended earlier today is past', (tester) async {
      await pumpEntryFor(
        tester,
        startAt: now.subtract(const Duration(hours: 5)),
        endAt: now.subtract(const Duration(hours: 1)),
      );
      await expectOnPast(tester);
    });

    testWidgets('a slot with a start but no end is upcoming', (tester) async {
      await pumpEntryFor(
        tester,
        startAt: now.subtract(const Duration(days: 10)),
      );
      await expectOnUpcoming(tester);
    });
  });

  group('editing an entry', () {
    Future<String> claimUpcoming({
      String name = 'Jane',
      String? phone,
      String? email,
      DateTime? date,
    }) async {
      final slotId = await addSlot(
        date: date ?? DateTime.now().add(const Duration(days: 3)),
      );
      final result = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: name,
        phone: phone,
        email: email,
        deviceId: 'device_1',
      );
      return result['entryId'] as String;
    }

    Future<void> openScreen(WidgetTester tester) async {
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
    }

    testWidgets('shows Edit on an upcoming entry but not on a past one', (
      tester,
    ) async {
      await claimUpcoming();
      await claimUpcoming(
        name: 'Old Jane',
        date: DateTime.now().subtract(const Duration(days: 3)),
      );
      await openScreen(tester);

      expect(find.text('Edit'), findsOneWidget);

      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();

      expect(find.text('Old Jane'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('opens the edit dialog filled in, without contact buttons', (
      tester,
    ) async {
      await claimUpcoming(phone: '+14255551234', email: 'jane@example.com');
      await openScreen(tester);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Entry'), findsOneWidget);
      expect(find.text('Jane'), findsWidgets);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('entryPhoneField')))
            .controller!
            .text,
        '4255551234',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('entryEmailField')))
            .controller!
            .text,
        'jane@example.com',
      );
      expect(find.byTooltip('WhatsApp'), findsNothing);
      expect(find.text('Remove Entry'), findsNothing);
    });

    testWidgets('saves the changes and shows them in the list', (tester) async {
      final entryId = await claimUpcoming(phone: '+14255551234');
      await openScreen(tester);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('entryNameField')),
        'Jane Smith',
      );
      await tester.enterText(
        find.byKey(const Key('entryEmailField')),
        'jane@example.com',
      );
      await tester.enterText(find.byKey(const Key('entryNoteField')), 'Sweets');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Entry updated successfully'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
      final saved = (await service.getAllEntries(signupId).first).firstWhere(
        (e) => e.id == entryId,
      );
      expect(saved.name, 'Jane Smith');
      expect(saved.note, 'Sweets');
      expect(saved.phone, '+14255551234');
      expect(saved.deviceId, 'device_1');
    });

    testWidgets('cancelling the dialog changes nothing', (tester) async {
      await claimUpcoming();
      await openScreen(tester);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('entryNameField')),
        'Someone Else',
      );
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text('Jane'), findsOneWidget);
      expect(find.text('Entry updated successfully'), findsNothing);
    });

    testWidgets('refuses a phone another entry in the slot already has', (
      tester,
    ) async {
      final slotId = await addSlot(
        date: DateTime.now().add(const Duration(days: 3)),
      );
      await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Amit',
        phone: '+14255559999',
        deviceId: 'device_2',
      );
      await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane',
        phone: '+14255551234',
        deviceId: 'device_1',
      );
      await openScreen(tester);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('entryPhoneField')),
        '4255559999',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "You've already signed up for this slot with this email or phone "
          'number.',
        ),
        findsOneWidget,
      );
      expect(find.text('Entry updated successfully'), findsNothing);
      final entries = await service.getAllEntries(signupId).first;
      expect(entries.firstWhere((e) => e.name == 'Jane').phone, '+14255551234');
    });

    testWidgets('shows an error snackbar when the update fails', (
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
        () => mockService.updateOwnEntry(
          signupId: any(named: 'signupId'),
          entryId: any(named: 'entryId'),
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          email: any(named: 'email'),
          pledgeAmount: any(named: 'pledgeAmount'),
          note: any(named: 'note'),
        ),
      ).thenThrow(Exception('permission-denied: secret details'));

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

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to update entry'), findsOneWidget);
      expect(find.textContaining('secret details'), findsNothing);
    });

    testWidgets('prefills the group\'s default country code for a new number', (
      tester,
    ) async {
      await claimUpcoming();
      final provider = _MockAppConfigProvider();
      when(() => provider.appConfig).thenReturn(
        AppConfig(
          deities: const [],
          gajananMaharajGroups: [
            GajananMaharajGroup(
              id: 'group_1',
              nameEn: 'Group',
              nameMr: 'गट',
              defaultCountryCode: '+91',
            ),
          ],
          socialMediaLinks: const [],
          appName: const {},
          updateMessage: const {},
          latestVersion: '1.0.0',
          forceUpdate: 'false',
          playStoreUrl: '',
          appStoreUrl: '',
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppConfigProvider>.value(
          value: provider,
          child: wrap(
            MySignupsScreen(
              signupId: signupId,
              groupId: 'group_1',
              deviceId: 'device_1',
              firestore: firestore,
              signupService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final code = tester.widget<TextFormField>(
        find.byKey(const Key('entryCountryCodeField')),
      );
      expect(code.controller!.text, '+91');
    });
  });
}

class _MockAppConfigProvider extends Mock implements AppConfigProvider {}

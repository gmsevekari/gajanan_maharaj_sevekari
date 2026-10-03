import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_slots_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAppConfigProvider extends Mock implements AppConfigProvider {}

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;
  late String signupId;
  late Signup signup;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
    final now = DateTime.now();
    signup = Signup(
      titleEn: 'Sunday Prasad Seva',
      titleMr: 'रविवार प्रसाद सेवा',
      groupId: 'group_1',
      status: SignupStatus.published,
      createdAt: now,
      updatedAt: now,
      createdBy: 'admin@test.com',
    );
    signupId = await service.createSignup(signup);
    signup = signup.copyWith(id: signupId);
  });

  Widget wrap(
    Widget child, {
    Locale? locale,
    AppConfigProvider? appConfigProvider,
  }) {
    return MultiProvider(
      providers: [
        if (appConfigProvider != null)
          ChangeNotifierProvider<AppConfigProvider>.value(
            value: appConfigProvider,
          ),
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

  Future<String> addSlot({String labelEn = 'Week 1', DateTime? date}) {
    return service.addSlot(
      signupId,
      SignupSlot(
        labelEn: labelEn,
        labelMr: 'आठवडा १',
        date: date,
        capacity: 3,
        sortOrder: 0,
        createdAt: DateTime.now(),
      ),
    );
  }

  testWidgets('shows a message on both tabs when there are no slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SignupSlotsScreen(
          signupId: signupId,
          signup: signup,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No slots here'), findsOneWidget);
  });

  testWidgets('lists a future slot on the Upcoming tab', (tester) async {
    await addSlot(date: DateTime.now().add(const Duration(days: 3)));

    await tester.pumpWidget(
      wrap(
        SignupSlotsScreen(
          signupId: signupId,
          signup: signup,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week 1'), findsOneWidget);
    expect(find.text('0 of 3 claimed'), findsOneWidget);
  });

  testWidgets('lists a past slot on the Past tab, not the Upcoming one', (
    tester,
  ) async {
    await addSlot(date: DateTime.now().subtract(const Duration(days: 3)));

    await tester.pumpWidget(
      wrap(
        SignupSlotsScreen(
          signupId: signupId,
          signup: signup,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No slots here'), findsOneWidget);
    expect(find.text('Week 1'), findsNothing);

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('Week 1'), findsOneWidget);
  });

  testWidgets('treats a slot with no date as upcoming', (tester) async {
    await addSlot();

    await tester.pumpWidget(
      wrap(
        SignupSlotsScreen(
          signupId: signupId,
          signup: signup,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week 1'), findsOneWidget);
  });

  testWidgets('does not show the names of devotees already signed up', (
    tester,
  ) async {
    final slotId = await addSlot();
    await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

    await tester.pumpWidget(
      wrap(
        SignupSlotsScreen(
          signupId: signupId,
          signup: signup,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 3 claimed'), findsOneWidget);
    expect(find.text('Jane'), findsNothing);
  });

  testWidgets('tapping Sign Up opens the claim dialog and claims the slot', (
    tester,
  ) async {
    await addSlot();

    await tester.pumpWidget(
      wrap(
        SignupSlotsScreen(
          signupId: signupId,
          signup: signup,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
    await tester.enterText(
      find.byKey(const Key('claimPhoneField')),
      '1234567890',
    );
    await tester.enterText(
      find.byKey(const Key('claimEmailField')),
      'jane@example.com',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text('1 of 3 claimed'), findsOneWidget);
    final entries = await service.getAllEntries(signupId).first;
    expect(entries.single.name, 'Jane');
  });

  testWidgets('tapping home icon navigates to home', (tester) async {
    await tester.pumpWidget(
      wrap(
        SignupSlotsScreen(
          signupId: signupId,
          signup: signup,
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
        SignupSlotsScreen(
          signupId: signupId,
          signup: signup,
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

  testWidgets('stays English under a Marathi app locale, including the claim '
      'dialog and dates', (tester) async {
    await addSlot(date: DateTime.now().add(const Duration(days: 3)));

    await tester.pumpWidget(
      wrap(
        SignupSlotsScreen(
          signupId: signupId,
          signup: signup,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
        locale: const Locale('mr'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);

    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pumpAndSettle();

    expect(find.text('Claim Slot'), findsOneWidget);
  });

  testWidgets('tab labels contrast with the app bar so the selected tab is '
      'visible', (tester) async {
    await tester.pumpWidget(
      wrap(
        SignupSlotsScreen(
          signupId: signupId,
          signup: signup,
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
        SignupSlotsScreen(
          signupId: signupId,
          signup: signup,
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

  testWidgets(
    'the claim dialog starts with the sign up group\'s country code',
    (tester) async {
      await addSlot(date: DateTime.now().add(const Duration(days: 3)));
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
        wrap(
          SignupSlotsScreen(
            signupId: signupId,
            signup: signup,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
          appConfigProvider: provider,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('signUpButton')));
      await tester.pumpAndSettle();

      final code = tester.widget<TextFormField>(
        find.byKey(const Key('claimCountryCodeField')),
      );
      expect(code.controller!.text, '+91');
    },
  );
}

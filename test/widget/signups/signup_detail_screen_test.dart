import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/signups/my_signups_screen.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_entries_screen.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_slots_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
  });

  Widget wrap(Widget child, {Locale? locale}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
      ],
      child: MaterialApp(
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

  Future<String> createOpenSignup({
    bool requiresJoinCode = false,
    String? headerImageUrl,
  }) async {
    final now = DateTime.now();
    return service.createSignup(
      Signup(
        titleEn: 'Sunday Prasad Seva',
        titleMr: 'रविवार प्रसाद सेवा',
        descriptionEn: 'Cook and serve prasad',
        descriptionMr: 'प्रसाद शिजवा आणि वाढा',
        groupId: 'group_1',
        status: SignupStatus.published,
        requiresJoinCode: requiresJoinCode,
        joinCode: requiresJoinCode ? 'ABC123' : null,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
        headerImageUrl: headerImageUrl,
      ),
    );
  }

  group('SignupDetailScreen', () {
    testWidgets('shows not-found message when the signup does not exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: 'missing',
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign up not found'), findsOneWidget);
    });

    testWidgets('tapping home icon navigates to home', (tester) async {
      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: 'missing',
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
          SignupDetailScreen(
            signupId: 'missing',
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

    testWidgets('renders the signup title, description, and nav cards', (
      tester,
    ) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sunday Prasad Seva'), findsOneWidget);
      expect(find.text('Cook and serve prasad'), findsOneWidget);
      expect(find.text('My Signups'), findsOneWidget);
      expect(find.text('Slots'), findsOneWidget);
      expect(find.text('Entries'), findsOneWidget);
    });

    testWidgets('tapping the My Sign Ups card opens MySignupsScreen', (
      tester,
    ) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Signups'));
      await tester.pumpAndSettle();

      expect(find.byType(MySignupsScreen), findsOneWidget);
    });

    testWidgets('tapping the Slots card opens SignupSlotsScreen', (
      tester,
    ) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Slots'));
      await tester.pumpAndSettle();

      expect(find.byType(SignupSlotsScreen), findsOneWidget);
    });

    testWidgets('tapping the Entries card opens SignupEntriesScreen', (
      tester,
    ) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entries'));
      await tester.pumpAndSettle();

      expect(find.byType(SignupEntriesScreen), findsOneWidget);
    });

    testWidgets('fetches the device id automatically when not injected', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'unique_device_id': 'mock-device-id',
      });
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('My Signups'), findsOneWidget);
    });

    testWidgets('resolves the signup id from ModalRoute arguments', (
      tester,
    ) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => FestivalProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (_) => SignupDetailScreen(
                deviceId: 'device_1',
                firestore: firestore,
                signupService: service,
              ),
            ),
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: RouteSettings(arguments: {'signupId': signupId}),
                    builder: (_) => SignupDetailScreen(
                      deviceId: 'device_1',
                      firestore: firestore,
                      signupService: service,
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Sunday Prasad Seva'), findsOneWidget);
    });

    testWidgets('renders the Marathi title when locale is mr', (tester) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('रविवार प्रसाद सेवा'), findsOneWidget);
    });

    testWidgets('falls back to the English description when Marathi is blank', (
      tester,
    ) async {
      final now = DateTime.now();
      final signupId = await service.createSignup(
        Signup(
          titleEn: 'Sunday Prasad Seva',
          titleMr: 'रविवार प्रसाद सेवा',
          descriptionEn: 'Cook and serve prasad',
          descriptionMr: '',
          groupId: 'group_1',
          status: SignupStatus.published,
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin@test.com',
        ),
      );

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cook and serve prasad'), findsOneWidget);
    });

    testWidgets('renders the header image when the signup has one', (
      tester,
    ) async {
      final signupId = await createOpenSignup(
        headerImageUrl: 'https://example.com/header.jpg',
      );

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Image.network makes a real HTTP request with no network access in
      // the test environment; expected and harmless here, since this
      // test only checks that an Image widget renders, not its pixels.
      tester.takeException();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders no image when the signup has none', (tester) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
    });
  });

  testWidgets('keeps UI text in English under a Marathi locale', (
    tester,
  ) async {
    final signupId = await createOpenSignup();

    await tester.pumpWidget(
      wrap(
        SignupDetailScreen(
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
    expect(find.text('Slots'), findsOneWidget);
    expect(find.text('Entries'), findsOneWidget);
    // Admin-entered content still follows the app language.
    expect(find.text('रविवार प्रसाद सेवा'), findsOneWidget);
  });

  testWidgets('falls back to the Marathi description when English is blank', (
    tester,
  ) async {
    final now = DateTime.now();
    final signupId = await service.createSignup(
      Signup(
        titleEn: 'Sunday Prasad Seva',
        titleMr: 'रविवार प्रसाद सेवा',
        descriptionEn: '',
        descriptionMr: 'प्रसाद शिजवा आणि वाढा',
        groupId: 'group_1',
        status: SignupStatus.published,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      ),
    );

    await tester.pumpWidget(
      wrap(
        SignupDetailScreen(
          signupId: signupId,
          deviceId: 'device_1',
          firestore: firestore,
          signupService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('प्रसाद शिजवा आणि वाढा'), findsOneWidget);
  });
}

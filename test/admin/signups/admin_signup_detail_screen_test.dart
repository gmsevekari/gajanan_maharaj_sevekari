import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_edit_signup_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_signup_entries_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_signup_slots_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_actions_row.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_status_section.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_header_image_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_join_code_row.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_overview_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_signup_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/slot_when_view.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

class MockSignupService extends Mock implements SignupService {}

/// Mirrors the FakeImagePickerPlatform used in
/// admin_create_signup_screen_test.dart.
class FakeImagePickerPlatform extends ImagePickerPlatform {
  final Uint8List? imageBytes;
  final String mimeType;

  FakeImagePickerPlatform({this.imageBytes, this.mimeType = 'image/jpeg'});

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    if (imageBytes == null) return null;
    return XFile.fromData(imageBytes!, mimeType: mimeType, name: 'header.jpg');
  }
}

/// A real, decodable 1x1 transparent PNG - Image.memory/.network actually
/// decode the bytes, so arbitrary filler bytes aren't enough.
final Uint8List _validPngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]);

/// Fails fast (instead of the unmocked default hanging indefinitely) so a
/// test can exercise the real error path of code that calls
/// getTemporaryDirectory().
class _ThrowingPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    throw Exception('no temp directory in tests');
  }
}

/// Hands out a real directory as the temp directory, so the export can write
/// its image.
class _TempPathProviderPlatform extends PathProviderPlatform {
  final String path;

  _TempPathProviderPlatform(this.path);

  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseStorage storage;
  late AdminUser adminUser;
  late MockAppConfigProvider appConfigProvider;

  setUpAll(() {
    registerFallbackValue(SignupStatus.published);
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      SignupEntry(
        id: 'dummy',
        slotId: 'dummy',
        name: 'dummy',
        joinedAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    firestore = FakeFirebaseFirestore();
    storage = MockFirebaseStorage();
    ImagePickerPlatform.instance = FakeImagePickerPlatform();
    adminUser = const AdminUser(
      email: 'admin@test.com',
      roles: ['group_admin'],
      groupId: 'gajanan_maharaj_seattle',
    );

    appConfigProvider = MockAppConfigProvider();
    final config = AppConfig(
      deities: const [],
      gajananMaharajGroups: [
        GajananMaharajGroup(
          id: 'gajanan_maharaj_seattle',
          nameEn: 'Seattle',
          nameMr: 'सिॲटल',
        ),
      ],
      socialMediaLinks: const [],
      appName: const {},
      updateMessage: const {},
      latestVersion: '1.0.0',
      forceUpdate: 'false',
      playStoreUrl: '',
      appStoreUrl: '',
    );
    when(() => appConfigProvider.appConfig).thenReturn(config);
  });

  Widget createWidget({
    required Widget child,
    Map<String, WidgetBuilder>? routes,
    Locale locale = const Locale('en'),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppConfigProvider>.value(
          value: appConfigProvider,
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
        routes: routes ?? {},
      ),
    );
  }

  void setLargeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
  }

  void resetScreen(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  Future<void> pumpDetailScreen(
    WidgetTester tester, {
    required String signupId,
    Map<String, WidgetBuilder>? routes,
    Locale locale = const Locale('en'),
  }) async {
    setLargeScreen(tester);
    addTearDown(() => resetScreen(tester));
    await tester.pumpWidget(
      createWidget(
        child: AdminSignupDetailScreen(
          signupId: signupId,
          adminUser: adminUser,
          firestore: firestore,
          storage: storage,
        ),
        routes: routes,
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AdminSignupDetailScreen', () {
    testWidgets('shows the sign up title in the app bar', (tester) async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Prasad Seva',
        'titleMr': 'प्रसाद सेवा',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.draft.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      await pumpDetailScreen(tester, signupId: signupRef.id);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Prasad Seva'),
        ),
        findsOneWidget,
      );
      expect(find.text('Sign Up Details'), findsNothing);
    });

    testWidgets('falls back to "Sign Up Details" when the signup is missing', (
      tester,
    ) async {
      await pumpDetailScreen(tester, signupId: 'missing_signup');

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Sign Up Details'),
        ),
        findsOneWidget,
      );
    });

    group('description', () {
      Future<String> seed({
        String descriptionEn = 'Help prepare prasad',
        String descriptionMr = 'प्रसाद बनवण्यासाठी मदत',
      }) async {
        final now = DateTime.now();
        final ref = await firestore.collection('signups').add({
          'titleEn': 'Prasad Seva',
          'titleMr': 'प्रसाद सेवा',
          'descriptionEn': descriptionEn,
          'descriptionMr': descriptionMr,
          'groupId': 'gajanan_maharaj_seattle',
          'status': SignupStatus.draft.name,
          'requiresJoinCode': false,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'createdBy': 'admin@test.com',
        });
        return ref.id;
      }

      Finder inBody(String text) =>
          find.descendant(of: find.byType(ListView), matching: find.text(text));

      testWidgets('shows below the header image', (tester) async {
        await pumpDetailScreen(tester, signupId: await seed());

        expect(inBody('Help prepare prasad'), findsOneWidget);
        final image = tester.getBottomLeft(find.byType(SignupHeaderImageCard));
        final description = tester.getTopLeft(inBody('Help prepare prasad'));
        expect(description.dy, greaterThanOrEqualTo(image.dy));
        // ...and above the status controls.
        final status = tester.getTopLeft(find.byType(SignupStatusSection));
        expect(description.dy, lessThan(status.dy));
      });

      testWidgets('is hidden when the signup has none', (tester) async {
        final id = await seed(descriptionEn: '', descriptionMr: '');
        await pumpDetailScreen(tester, signupId: id);

        final image = tester.getBottomLeft(find.byType(SignupHeaderImageCard));
        final status = tester.getTopLeft(find.byType(SignupStatusSection));
        // Only the normal gap separates the image card and status card.
        expect(status.dy - image.dy, lessThan(20));
      });

      testWidgets('follows the app language', (tester) async {
        await pumpDetailScreen(
          tester,
          signupId: await seed(),
          locale: const Locale('mr'),
        );

        expect(inBody('प्रसाद बनवण्यासाठी मदत'), findsOneWidget);
        expect(inBody('Help prepare prasad'), findsNothing);
      });

      testWidgets('falls back to English when the Marathi one is blank', (
        tester,
      ) async {
        final id = await seed(descriptionMr: '');
        await pumpDetailScreen(
          tester,
          signupId: id,
          locale: const Locale('mr'),
        );

        expect(inBody('Help prepare prasad'), findsOneWidget);
      });
    });

    group('slots and entries cards', () {
      Future<String> seedWithSlotAndEntry() async {
        final now = DateTime.now();
        final ref = await firestore.collection('signups').add({
          'titleEn': 'Prasad Seva',
          'titleMr': '',
          'groupId': 'gajanan_maharaj_seattle',
          'status': SignupStatus.published.name,
          'requiresJoinCode': false,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'createdBy': 'admin@test.com',
        });
        final slot = await ref.collection('slots').add({
          'labelEn': 'Morning Seva',
          'labelMr': '',
          'capacity': 3,
          'claimedCount': 1,
          'sortOrder': 0,
          'createdAt': Timestamp.fromDate(now),
        });
        await ref.collection('entries').add({
          'slotId': slot.id,
          'name': 'Ram Das',
          'joinedAt': Timestamp.fromDate(now),
        });
        return ref.id;
      }

      testWidgets('replace the inline slot and entry lists', (tester) async {
        await pumpDetailScreen(tester, signupId: await seedWithSlotAndEntry());

        expect(find.text('Slots'), findsOneWidget);
        expect(find.text('Entries'), findsOneWidget);
        // Nothing from the slots or entries is listed in the screen body any
        // more (the hidden export image still contains them).
        Finder inBody(String text) => find.descendant(
          of: find.byType(ListView),
          matching: find.text(text),
        );
        expect(inBody('Morning Seva'), findsNothing);
        expect(inBody('Ram Das'), findsNothing);
        expect(find.text('Add Devotee'), findsNothing);
        expect(find.text('Slots & Entries'), findsNothing);
      });

      testWidgets('open the Slots screen', (tester) async {
        await pumpDetailScreen(tester, signupId: await seedWithSlotAndEntry());

        await tester.tap(find.text('Slots'));
        await tester.pumpAndSettle();

        expect(find.byType(AdminSignupSlotsScreen), findsOneWidget);
        expect(find.text('Morning Seva'), findsOneWidget);
        expect(find.text('Add Devotee'), findsOneWidget);
      });

      testWidgets('open the Entries screen', (tester) async {
        await pumpDetailScreen(tester, signupId: await seedWithSlotAndEntry());

        await tester.tap(find.text('Entries'));
        await tester.pumpAndSettle();

        expect(find.byType(AdminSignupEntriesScreen), findsOneWidget);
        expect(find.text('Ram Das'), findsOneWidget);
      });

      testWidgets('sit below the actions', (tester) async {
        await pumpDetailScreen(tester, signupId: await seedWithSlotAndEntry());

        final actions = tester.getBottomLeft(find.text('Export Summary'));
        expect(
          tester.getTopLeft(find.text('Slots')).dy,
          greaterThan(actions.dy),
        );
        expect(
          tester.getTopLeft(find.text('Entries')).dy,
          greaterThan(tester.getTopLeft(find.text('Slots')).dy),
        );
      });
    });

    group('editing the sign up', () {
      Future<DocumentReference<Map<String, dynamic>>> seedEditable({
        bool requiresJoinCode = false,
        String? joinCode,
      }) {
        final now = DateTime.now();
        return firestore.collection('signups').add({
          'titleEn': 'Prasad Seva',
          'titleMr': 'प्रसाद सेवा',
          'descriptionEn': 'Cook and serve',
          'descriptionMr': '',
          'groupId': 'gajanan_maharaj_seattle',
          'status': SignupStatus.published.name,
          'requiresJoinCode': requiresJoinCode,
          'joinCode': joinCode,
          'headerImageUrl': 'https://example.com/h.png',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'createdBy': 'admin@test.com',
        });
      }

      Future<void> tapEdit(WidgetTester tester) async {
        final edit = find.widgetWithText(TextButton, 'Edit');
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
      }

      testWidgets('offers an Edit button', (tester) async {
        final ref = await seedEditable();
        await pumpDetailScreen(tester, signupId: ref.id);

        expect(find.widgetWithText(TextButton, 'Edit'), findsOneWidget);
      });

      testWidgets('opens the Edit Sign Up screen with the current values', (
        tester,
      ) async {
        final ref = await seedEditable();
        await pumpDetailScreen(tester, signupId: ref.id);

        await tapEdit(tester);

        expect(find.byType(AdminEditSignupScreen), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('titleEnField')))
              .controller!
              .text,
          'Prasad Seva',
        );
      });

      testWidgets('saving shows the new title and description on the page, '
          'and confirms', (tester) async {
        final ref = await seedEditable();
        await pumpDetailScreen(tester, signupId: ref.id);

        await tapEdit(tester);
        await tester.enterText(
          find.byKey(const Key('titleEnField')),
          'Annadanam',
        );
        await tester.enterText(
          find.byKey(const Key('descEnField')),
          'Serve lunch',
        );
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.byType(AdminEditSignupScreen), findsNothing);
        expect(find.text('Sign up updated successfully'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Annadanam'),
          ),
          findsOneWidget,
        );
        final inBody = find.descendant(
          of: find.byType(ListView),
          matching: find.text('Serve lunch'),
        );
        expect(inBody, findsOneWidget);
        expect(find.text('Cook and serve'), findsNothing);
      });

      testWidgets('keeps the status and the header image', (tester) async {
        final ref = await seedEditable();
        await pumpDetailScreen(tester, signupId: ref.id);

        await tapEdit(tester);
        await tester.enterText(find.byKey(const Key('titleEnField')), 'New');
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final data = (await ref.get()).data()!;
        expect(data['status'], 'published');
        expect(data['headerImageUrl'], 'https://example.com/h.png');
      });

      testWidgets('turning the join code on shows the new code on the page', (
        tester,
      ) async {
        final ref = await seedEditable();
        await pumpDetailScreen(tester, signupId: ref.id);
        expect(find.byType(SignupJoinCodeRow), findsNothing);

        await tapEdit(tester);
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Save'));
        await tester.pumpAndSettle();

        expect(find.byType(SignupJoinCodeRow), findsOneWidget);
        final code = (await ref.get()).data()!['joinCode'] as String;
        expect(code, matches(RegExp(r'^[A-Z0-9]{6}$')));
        expect(find.text(code), findsOneWidget);
      });

      testWidgets('turning the join code off removes it from the page', (
        tester,
      ) async {
        final ref = await seedEditable(
          requiresJoinCode: true,
          joinCode: 'ABC123',
        );
        await pumpDetailScreen(tester, signupId: ref.id);
        expect(find.text('ABC123'), findsOneWidget);

        await tapEdit(tester);
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Save'));
        await tester.pumpAndSettle();

        expect(find.text('ABC123'), findsNothing);
        expect(find.byType(SignupJoinCodeRow), findsNothing);
      });

      testWidgets('shows no confirmation when the edit is abandoned', (
        tester,
      ) async {
        final ref = await seedEditable();
        await pumpDetailScreen(tester, signupId: ref.id);

        await tapEdit(tester);
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.byType(AdminEditSignupScreen), findsNothing);
        expect(find.text('Sign up updated successfully'), findsNothing);
      });
    });

    testWidgets('renders not found state when signup does not exist', (
      tester,
    ) async {
      await pumpDetailScreen(tester, signupId: 'missing_signup');
      expect(find.text('Sign up not found'), findsOneWidget);
    });

    testWidgets('tapping home icon pops until first route', (tester) async {
      await pumpDetailScreen(tester, signupId: 'missing_signup');

      expect(find.byType(IconButton), findsWidgets);
      await tester.tap(
        find
            .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
            .first,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('tapping settings icon navigates to settings route', (
      tester,
    ) async {
      var navigatedToSettings = false;
      await pumpDetailScreen(
        tester,
        signupId: 'missing_signup',
        routes: {
          Routes.settings: (context) {
            navigatedToSettings = true;
            return const Scaffold(body: Text('Settings Mock'));
          },
        },
      );

      await tester.tap(
        find
            .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
            .at(1),
      );
      await tester.pumpAndSettle();

      expect(navigatedToSettings, isTrue);
      expect(find.text('Settings Mock'), findsOneWidget);
    });

    testWidgets('renders signup info, join code, and duplicate button', (
      tester,
    ) async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Prasad Seva',
        'titleMr': 'प्रसाद सेवा',
        'descriptionEn': 'Help prepare prasad',
        'descriptionMr': 'प्रसाद बनवण्यासाठी मदत',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.draft.name,
        'requiresJoinCode': true,
        'joinCode': 'JOIN99',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      await pumpDetailScreen(tester, signupId: signupRef.id);

      expect(find.text('Prasad Seva').first, findsOneWidget);
      // The card shows no description (the hidden export image still does).
      expect(
        find.descendant(
          of: find.byType(SignupOverviewCard),
          matching: find.text('Help prepare prasad'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(SignupOverviewCard),
          matching: find.text('JOIN99'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SignupOverviewCard),
          matching: find.text('Draft'),
        ),
        findsOneWidget,
      );
      expect(find.text('JOIN99'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Export Summary'), findsOneWidget);
    });

    testWidgets('copies join code to clipboard', (tester) async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Prasad Seva',
        'titleMr': 'प्रसाद सेवा',
        'descriptionEn': 'Description',
        'descriptionMr': 'वर्णन',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': true,
        'joinCode': 'JOIN99',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      await pumpDetailScreen(tester, signupId: signupRef.id);

      await tester.tap(find.byTooltip('Copy Join Code'));
      await tester.pumpAndSettle();

      expect(find.text('Join Code copied to clipboard'), findsOneWidget);
    });

    testWidgets('unlocks and updates status to published', (tester) async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Draft Signup',
        'titleMr': 'मसुदा',
        'descriptionEn': 'Draft',
        'descriptionMr': 'मसुदा',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.draft.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      await pumpDetailScreen(tester, signupId: signupRef.id);

      // Initially locked
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      // Tap unlock
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_open), findsOneWidget);

      // Tap Published segment
      await tester.tap(find.text('Published'));
      await tester.pumpAndSettle();

      // Verify Firestore status updated
      final updated = await firestore
          .collection('signups')
          .doc(signupRef.id)
          .get();
      expect(updated.data()?['status'], 'published');
      expect(find.text('Status updated successfully'), findsOneWidget);
    });

    testWidgets('duplicate button copies signup and navigates to new draft', (
      tester,
    ) async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Original Signup',
        'titleMr': 'मूळ शीट',
        'descriptionEn': 'Desc',
        'descriptionMr': 'वर्णन',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': true,
        'joinCode': 'ORIG01',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      await signupRef.collection('slots').add({
        'labelEn': 'Slot 1',
        'labelMr': 'स्लॉट १',
        'capacity': 3,
        'claimedCount': 2,
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(now),
      });

      String? navSignupId;
      await pumpDetailScreen(
        tester,
        signupId: signupRef.id,
        routes: {
          Routes.adminSignupDetail: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            navSignupId = args?['signupId'] as String?;
            return const Scaffold(body: Text('Duplicated Screen Mock'));
          },
        },
      );

      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();

      expect(navSignupId, isNotNull);
      expect(navSignupId, isNot(equals(signupRef.id)));
      expect(find.text('Duplicated Screen Mock'), findsOneWidget);

      // Verify duplicate exists in Firestore as draft with 0 claimedCount
      final duplicateDoc = await firestore
          .collection('signups')
          .doc(navSignupId)
          .get();
      expect(duplicateDoc.data()?['status'], 'draft');
      expect(duplicateDoc.data()?['titleEn'], 'Original Signup');

      final duplicateSlots = await firestore
          .collection('signups')
          .doc(navSignupId)
          .collection('slots')
          .get();
      expect(duplicateSlots.docs.length, 1);
      expect(duplicateSlots.docs.first.data()['claimedCount'], 0);
    });

    testWidgets(
      'keeps the UI in English but shows Marathi content when locale is mr',
      (tester) async {
        final now = DateTime.now();
        final signupRef = await firestore.collection('signups').add({
          'titleEn': 'Prasad Seva',
          'titleMr': 'प्रसाद सेवा',
          'descriptionEn': 'Help',
          'descriptionMr': 'मदत',
          'groupId': 'gajanan_maharaj_seattle',
          'status': SignupStatus.draft.name,
          'requiresJoinCode': false,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'createdBy': 'admin@test.com',
        });

        await pumpDetailScreen(
          tester,
          signupId: signupRef.id,
          locale: const Locale('mr'),
        );

        // UI text stays English; admin-entered content follows the app locale.
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('प्रसाद सेवा'),
          ),
          findsOneWidget,
        );
        expect(find.text('प्रसाद सेवा').first, findsOneWidget);
        expect(find.text('Duplicate'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);
        expect(find.text('Slots'), findsOneWidget);
        expect(find.text('Entries'), findsOneWidget);
      },
    );

    testWidgets('shows error snackbar when duplicateSignup throws', (
      tester,
    ) async {
      final now = DateTime.now();
      final signup = Signup(
        id: 'signup_err',
        titleEn: 'Error Signup',
        titleMr: 'त्रुटी शीट',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupStatus.draft,
        requiresJoinCode: false,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      );

      final mockService = MockSignupService();
      when(
        () => mockService.getSignupById('signup_err'),
      ).thenAnswer((_) => Stream.value(signup));
      when(
        () => mockService.getSlots('signup_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getAllEntries('signup_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.duplicateSignup('signup_err'),
      ).thenThrow(Exception('Firestore error'));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            signupId: 'signup_err',
            adminUser: adminUser,
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to duplicate sign up'), findsOneWidget);
    });

    testWidgets('shows error snackbar when updateSignupStatus throws', (
      tester,
    ) async {
      final now = DateTime.now();
      final signup = Signup(
        id: 'signup_status_err',
        titleEn: 'Status Error Signup',
        titleMr: 'शीट',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupStatus.draft,
        requiresJoinCode: false,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      );

      final mockService = MockSignupService();
      when(
        () => mockService.getSignupById('signup_status_err'),
      ).thenAnswer((_) => Stream.value(signup));
      when(
        () => mockService.getSlots('signup_status_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getAllEntries('signup_status_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.updateSignupStatus('signup_status_err', any()),
      ).thenThrow(Exception('Network error'));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            signupId: 'signup_status_err',
            adminUser: adminUser,
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Published'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to update status'), findsOneWidget);
    });

    testWidgets(
      'resolves arguments from ModalRoute settings when not in constructor',
      (tester) async {
        final now = DateTime.now();
        final signupRef = await firestore.collection('signups').add({
          'titleEn': 'Route Args Signup',
          'titleMr': 'शीट',
          'descriptionEn': '',
          'descriptionMr': '',
          'groupId': 'gajanan_maharaj_seattle',
          'status': SignupStatus.published.name,
          'requiresJoinCode': false,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'createdBy': 'admin@test.com',
        });

        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));

        await tester.pumpWidget(
          createWidget(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: RouteSettings(
                          name: Routes.adminSignupDetail,
                          arguments: {
                            'signupId': signupRef.id,
                            'adminUser': adminUser,
                          },
                        ),
                        builder: (_) =>
                            AdminSignupDetailScreen(firestore: firestore),
                      ),
                    );
                  },
                  child: const Text('Go To Detail'),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Go To Detail'));
        await tester.pumpAndSettle();

        expect(find.text('Route Args Signup').first, findsOneWidget);
      },
    );

    testWidgets('triggers deep link share when share button is tapped', (
      tester,
    ) async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Shareable Signup',
        'titleMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': true,
        'joinCode': 'CODE12',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            signupId: signupRef.id,
            adminUser: adminUser,
            firestore: firestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Share'));
      await tester.pumpAndSettle();
    });

    testWidgets('triggers export summary when export button is tapped', (
      tester,
    ) async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Exportable Signup',
        'titleMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            signupId: signupRef.id,
            adminUser: adminUser,
            firestore: firestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Export Summary'));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'shows error snackbar when export fails after capturing the screenshot',
      (tester) async {
        // ScreenshotController.capture() returns null in the widget-test
        // environment (no real rendering surface), which is why the
        // "triggers export summary" test above never reaches the file
        // write/share code at all. Injecting a capture override that
        // returns real bytes gets past that early return; PathProviderPlatform
        // is then swapped for a fake that throws, so getTemporaryDirectory()
        // fails fast and predictably instead of hanging on an unmocked
        // platform channel (which pumpAndSettle would never wait out).
        final originalPathProvider = PathProviderPlatform.instance;
        PathProviderPlatform.instance = _ThrowingPathProviderPlatform();
        addTearDown(() {
          PathProviderPlatform.instance = originalPathProvider;
        });

        final now = DateTime.now();
        final signupRef = await firestore.collection('signups').add({
          'titleEn': 'Exportable Signup',
          'titleMr': '',
          'groupId': 'gajanan_maharaj_seattle',
          'status': SignupStatus.published.name,
          'requiresJoinCode': false,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'createdBy': 'admin@test.com',
        });

        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));

        await tester.pumpWidget(
          createWidget(
            child: AdminSignupDetailScreen(
              signupId: signupRef.id,
              adminUser: adminUser,
              firestore: firestore,
              exportCapture: () async => Uint8List.fromList([1, 2, 3]),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Export Summary'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to export image'), findsOneWidget);
      },
    );

    testWidgets('shows loading overlay when isProcessing is true', (
      tester,
    ) async {
      final now = DateTime.now();
      const signupId = 'processing_signup';
      final signup = Signup(
        id: signupId,
        titleEn: 'Processing Signup',
        titleMr: '',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupStatus.draft,
        requiresJoinCode: false,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      );
      final completer = Completer<String>();
      final mockService = MockSignupService();
      when(
        () => mockService.getSignupById(signupId),
      ).thenAnswer((_) => Stream.value(signup));
      when(
        () => mockService.getSlots(signupId),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getAllEntries(signupId),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.duplicateSignup(signupId),
      ).thenAnswer((_) => completer.future);

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            signupId: signupId,
            adminUser: adminUser,
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duplicate'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete('new_id');
      await tester.pumpAndSettle();
    });
  });

  group('AdminSignupDetailScreen header image', () {
    // Image.network makes a real HTTP request with no network access in
    // the test environment, so it always fails - that's expected here
    // (these tests only care about the button/Firestore state, not the
    // decoded pixels). Consume it so it doesn't fail the test, asserting
    // it really is that harmless, expected exception and not a real bug.
    void drainNetworkImageErrors(WidgetTester tester) {
      final exception = tester.takeException();
      if (exception != null) {
        expect(exception, isA<NetworkImageLoadException>());
      }
    }

    Future<String> seedSignup({String? headerImageUrl}) async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Prasad Seva',
        'titleMr': 'प्रसाद सेवा',
        'descriptionEn': 'Description',
        'descriptionMr': 'वर्णन',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.draft.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
        'headerImageUrl': headerImageUrl,
      });
      return signupRef.id;
    }

    testWidgets('shows Add Image when the signup has no image', (tester) async {
      final signupId = await seedSignup();

      await pumpDetailScreen(tester, signupId: signupId);

      expect(find.text('Add Image'), findsOneWidget);
      expect(find.text('Replace Image'), findsNothing);
      expect(find.text('Remove Image'), findsNothing);
    });

    testWidgets(
      'shows a preview and Replace/Remove when the signup has an image',
      (tester) async {
        final signupId = await seedSignup(
          headerImageUrl: 'https://example.com/header.jpg',
        );

        await pumpDetailScreen(tester, signupId: signupId);
        drainNetworkImageErrors(tester);

        expect(find.text('Replace Image'), findsOneWidget);
        expect(find.text('Remove Image'), findsOneWidget);
        expect(find.text('Add Image'), findsNothing);
      },
    );

    testWidgets('picking an image uploads it and updates headerImageUrl', (
      tester,
    ) async {
      ImagePickerPlatform.instance = FakeImagePickerPlatform(
        imageBytes: _validPngBytes,
      );
      final signupId = await seedSignup();

      await pumpDetailScreen(tester, signupId: signupId);
      await tester.tap(find.byKey(const Key('addOrReplaceHeaderImageButton')));
      await tester.pumpAndSettle();
      drainNetworkImageErrors(tester);

      final doc = await firestore.collection('signups').doc(signupId).get();
      expect(doc.data()?['headerImageUrl'], isNotNull);
      expect(
        storage.storedDataMap.containsKey('signups/$signupId/header'),
        true,
      );
      expect(find.text('Replace Image'), findsOneWidget);
    });

    testWidgets('shows an error when the picked file is too large', (
      tester,
    ) async {
      ImagePickerPlatform.instance = FakeImagePickerPlatform(
        imageBytes: Uint8List(3 * 1024 * 1024),
      );
      final signupId = await seedSignup();

      await pumpDetailScreen(tester, signupId: signupId);
      await tester.tap(find.byKey(const Key('addOrReplaceHeaderImageButton')));
      await tester.pumpAndSettle();

      expect(find.text('Image must be smaller than 2 MB'), findsOneWidget);
      expect(find.text('Add Image'), findsOneWidget);
    });

    testWidgets('shows an error snackbar when the upload fails', (
      tester,
    ) async {
      final now = DateTime.now();
      final signup = Signup(
        id: 'signup_img_err',
        titleEn: 'Error Signup',
        titleMr: 'त्रुटी शीट',
        groupId: 'gajanan_maharaj_seattle',
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      );
      final mockService = MockSignupService();
      when(
        () => mockService.getSignupById('signup_img_err'),
      ).thenAnswer((_) => Stream.value(signup));
      when(
        () => mockService.getSlots('signup_img_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getAllEntries('signup_img_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.uploadHeaderImage(
          signupId: any(named: 'signupId'),
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
        ),
      ).thenThrow(Exception('upload failed'));

      ImagePickerPlatform.instance = FakeImagePickerPlatform(
        imageBytes: _validPngBytes,
      );

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));
      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            signupId: 'signup_img_err',
            adminUser: adminUser,
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addOrReplaceHeaderImageButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to upload image. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('cancelling the remove-image dialog keeps the image', (
      tester,
    ) async {
      final signupId = await seedSignup(
        headerImageUrl: 'https://example.com/header.jpg',
      );

      await pumpDetailScreen(tester, signupId: signupId);
      drainNetworkImageErrors(tester);
      await tester.tap(find.byKey(const Key('removeHeaderImageButton')));
      await tester.pumpAndSettle();

      expect(find.text('Remove Image?'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      drainNetworkImageErrors(tester);

      final doc = await firestore.collection('signups').doc(signupId).get();
      expect(doc.data()?['headerImageUrl'], 'https://example.com/header.jpg');
    });

    testWidgets('confirming removal clears headerImageUrl', (tester) async {
      final signupId = await seedSignup(
        headerImageUrl: 'https://example.com/header.jpg',
      );

      await pumpDetailScreen(tester, signupId: signupId);
      drainNetworkImageErrors(tester);
      await tester.tap(find.byKey(const Key('removeHeaderImageButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      final doc = await firestore.collection('signups').doc(signupId).get();
      expect(doc.data()?['headerImageUrl'], isNull);
      expect(find.text('Add Image'), findsOneWidget);
    });

    testWidgets(
      'hides add/replace/remove buttons while a removal is in flight',
      (tester) async {
        final now = DateTime.now();
        final signup = Signup(
          id: 'signup_removing',
          titleEn: 'Removing Signup',
          titleMr: 'काढत आहे',
          groupId: 'gajanan_maharaj_seattle',
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin@test.com',
          headerImageUrl: 'https://example.com/header.jpg',
        );
        final mockService = MockSignupService();
        when(
          () => mockService.getSignupById('signup_removing'),
        ).thenAnswer((_) => Stream.value(signup));
        when(
          () => mockService.getSlots('signup_removing'),
        ).thenAnswer((_) => Stream.value(const []));
        when(
          () => mockService.getAllEntries('signup_removing'),
        ).thenAnswer((_) => Stream.value(const []));
        final removeCompleter = Completer<void>();
        when(
          () => mockService.removeHeaderImage('signup_removing'),
        ).thenAnswer((_) => removeCompleter.future);

        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));
        await tester.pumpWidget(
          createWidget(
            child: AdminSignupDetailScreen(
              signupId: 'signup_removing',
              adminUser: adminUser,
              signupService: mockService,
            ),
          ),
        );
        await tester.pumpAndSettle();
        drainNetworkImageErrors(tester);

        await tester.tap(find.byKey(const Key('removeHeaderImageButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes'));
        await tester.pump();

        // The removal is still pending (removeCompleter hasn't completed),
        // so neither button should be tappable - this is what prevents a
        // Replace tap from racing a Remove that's still in flight.
        expect(
          find.byKey(const Key('addOrReplaceHeaderImageButton')),
          findsNothing,
        );
        expect(find.byKey(const Key('removeHeaderImageButton')), findsNothing);

        removeCompleter.complete();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('shows an error snackbar when removal fails', (tester) async {
      final now = DateTime.now();
      final signup = Signup(
        id: 'signup_remove_err',
        titleEn: 'Error Signup',
        titleMr: 'त्रुटी शीट',
        groupId: 'gajanan_maharaj_seattle',
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
        headerImageUrl: 'https://example.com/header.jpg',
      );
      final mockService = MockSignupService();
      when(
        () => mockService.getSignupById('signup_remove_err'),
      ).thenAnswer((_) => Stream.value(signup));
      when(
        () => mockService.getSlots('signup_remove_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getAllEntries('signup_remove_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.removeHeaderImage('signup_remove_err'),
      ).thenThrow(Exception('remove failed'));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));
      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            signupId: 'signup_remove_err',
            adminUser: adminUser,
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      drainNetworkImageErrors(tester);

      await tester.tap(find.byKey(const Key('removeHeaderImageButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to remove image. Please try again.'),
        findsOneWidget,
      );
    });
  });

  group('AdminSignupDetailScreen delete', () {
    Future<String> seedSignupWithSlot() async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Prasad Seva',
        'titleMr': 'प्रसाद सेवा',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.draft.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });
      await signupRef.collection('slots').add({
        'labelEn': 'Week 1',
        'labelMr': 'आठवडा १',
        'capacity': 3,
        'claimedCount': 0,
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(now),
      });
      return signupRef.id;
    }

    Future<void> pumpPushedDetailScreen(
      WidgetTester tester, {
      required String signupId,
      SignupService? signupService,
    }) async {
      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));
      await tester.pumpWidget(
        createWidget(
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminSignupDetailScreen(
                        signupId: signupId,
                        adminUser: adminUser,
                        firestore: firestore,
                        storage: storage,
                        signupService: signupService,
                      ),
                    ),
                  ),
                  child: const Text('Open detail'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open detail'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks for confirmation and keeps the signup on No', (
      tester,
    ) async {
      final signupId = await seedSignupWithSlot();
      await pumpPushedDetailScreen(tester, signupId: signupId);

      await tester.tap(find.byKey(const Key('deleteSignupButton')));
      await tester.pumpAndSettle();

      expect(find.text('Delete Sign Up?'), findsOneWidget);
      // Asking is not deleting: nothing is removed until it is confirmed.
      expect(
        (await firestore.collection('signups').doc(signupId).get()).exists,
        isTrue,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Sign Up?'), findsNothing);
      expect(find.byType(AdminSignupDetailScreen), findsOneWidget);
      final doc = await firestore.collection('signups').doc(signupId).get();
      expect(doc.exists, isTrue);
    });

    testWidgets('keeps the signup when the dialog is dismissed', (
      tester,
    ) async {
      final signupId = await seedSignupWithSlot();
      await pumpPushedDetailScreen(tester, signupId: signupId);

      await tester.tap(find.byKey(const Key('deleteSignupButton')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Delete Sign Up?'), findsNothing);
      final doc = await firestore.collection('signups').doc(signupId).get();
      expect(doc.exists, isTrue);
    });

    testWidgets('is on the overview card, beside Edit, not in the actions', (
      tester,
    ) async {
      final signupId = await seedSignupWithSlot();
      await pumpPushedDetailScreen(tester, signupId: signupId);

      expect(
        find.descendant(
          of: find.byType(SignupOverviewCard),
          matching: find.byKey(const Key('deleteSignupButton')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SignupActionsRow),
          matching: find.text('Delete'),
        ),
        findsNothing,
      );
    });

    testWidgets('confirm dialog offers Cancel and a red Delete', (
      tester,
    ) async {
      final signupId = await seedSignupWithSlot();
      await pumpPushedDetailScreen(tester, signupId: signupId);

      await tester.tap(find.byKey(const Key('deleteSignupButton')));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('Cancel')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('No')),
        findsNothing,
      );
      final delete = find.descendant(of: dialog, matching: find.text('Delete'));
      expect(delete, findsOneWidget);
      expect(
        tester.widget<Text>(delete).style?.color,
        Theme.of(tester.element(dialog)).colorScheme.error,
      );
    });

    testWidgets('deleting removes the signup and returns to the previous '
        'screen', (tester) async {
      final signupId = await seedSignupWithSlot();
      await pumpPushedDetailScreen(tester, signupId: signupId);

      await tester.tap(find.byKey(const Key('deleteSignupButton')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      final signupRef = firestore.collection('signups').doc(signupId);
      expect((await signupRef.get()).exists, isFalse);
      expect((await signupRef.collection('slots').get()).docs, isEmpty);
      expect(find.byType(AdminSignupDetailScreen), findsNothing);
      expect(find.text('Open detail'), findsOneWidget);
      expect(find.text('Sign up deleted'), findsOneWidget);
    });

    testWidgets('shows an error and stays on the screen when delete fails', (
      tester,
    ) async {
      final now = DateTime.now();
      final signup = Signup(
        id: 'signup_del_err',
        titleEn: 'Delete Error Signup',
        titleMr: 'त्रुटी',
        groupId: 'gajanan_maharaj_seattle',
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      );
      final mockService = MockSignupService();
      when(
        () => mockService.getSignupById('signup_del_err'),
      ).thenAnswer((_) => Stream.value(signup));
      when(
        () => mockService.getSlots('signup_del_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getAllEntries('signup_del_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.deleteSignup('signup_del_err'),
      ).thenThrow(Exception('Firestore error'));

      await pumpPushedDetailScreen(
        tester,
        signupId: 'signup_del_err',
        signupService: mockService,
      );
      await tester.tap(find.byKey(const Key('deleteSignupButton')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to delete sign up. Please try again.'),
        findsOneWidget,
      );
      expect(find.byType(AdminSignupDetailScreen), findsOneWidget);
    });
  });

  group('AdminSignupDetailScreen export sign ups', () {
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    late List<MethodCall> shareCalls;
    late List<Widget> capturedCards;
    late List<double> capturedRatios;
    late Directory tempDir;

    setUp(() {
      shareCalls = [];
      capturedCards = [];
      capturedRatios = [];
      tempDir = Directory.systemTemp.createTempSync('signup_export_test');
      final original = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _TempPathProviderPlatform(tempDir.path);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(shareChannel, (call) async {
            shareCalls.add(call);
            return 'dev.fluttercommunity.plus/share/success';
          });
      addTearDown(() {
        PathProviderPlatform.instance = original;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(shareChannel, null);
        tempDir.deleteSync(recursive: true);
      });
    });

    Future<void> addSlot(
      DocumentReference<Map<String, dynamic>> signup,
      String id,
      String label, {
      required Duration from,
      List<String> names = const [],
    }) async {
      final start = DateTime.now().add(from);
      await signup.collection('slots').doc(id).set({
        'labelEn': label,
        'labelMr': '',
        'startAt': Timestamp.fromDate(start),
        'endAt': Timestamp.fromDate(start.add(const Duration(hours: 2))),
        'timezone': 'America/Los_Angeles',
        'capacity': 5,
        'claimedCount': names.length,
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      for (final name in names) {
        await signup.collection('entries').add({
          'slotId': id,
          'name': name,
          'phone': '12065550100',
          'email': '$name@example.com',
          'joinedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    }

    Future<String> seed({bool withEntries = true}) async {
      final now = DateTime.now();
      final signup = await firestore.collection('signups').add({
        'titleEn': 'Prasad Seva',
        'titleMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });
      await addSlot(
        signup,
        'soon',
        'Soon Seva',
        from: const Duration(days: 3),
        names: withEntries ? ['Asha'] : [],
      );
      await addSlot(
        signup,
        'later',
        'Later Seva',
        from: const Duration(days: 5),
        names: withEntries ? ['Bhau', 'Bina'] : [],
      );
      await addSlot(
        signup,
        'old',
        'Old Seva',
        from: const Duration(days: -5),
        names: withEntries ? ['Pastor'] : [],
      );
      await addSlot(
        signup,
        'empty',
        'Empty Seva',
        from: const Duration(days: 9),
      );
      return signup.id;
    }

    Future<void> pumpScreen(
      WidgetTester tester,
      String signupId, {
      Future<Uint8List> Function(Widget card, double pixelRatio)? capture,
      bool realCapture = false,
    }) async {
      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));
      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            signupId: signupId,
            adminUser: adminUser,
            firestore: firestore,
            storage: storage,
            entriesExportCapture: realCapture
                ? null
                : capture ??
                      (card, pixelRatio) async {
                        capturedCards.add(card);
                        capturedRatios.add(pixelRatio);
                        return Uint8List.fromList([1, 2, 3]);
                      },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openPicker(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Export Sign Ups'));
      await tester.pumpAndSettle();
    }

    /// Lets the real file write finish. Each step of it completes in real
    /// time but only continues on the next pump, so alternate the two until
    /// the progress overlay is gone.
    Future<void> settleRealIo(WidgetTester tester) async {
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
      await tester.pumpAndSettle();
    }

    /// Taps Export in the picker and waits for the export to finish.
    Future<void> confirmExport(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(TextButton, 'Export'));
      await tester.pump();
      await settleRealIo(tester);
    }

    /// The names the captured card shows, built the way the capture builds it.
    Future<void> showCapturedCard(WidgetTester tester, [int index = 0]) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: capturedCards[index],
        ),
      );
    }

    testWidgets('opens a picker of the upcoming slots only', (tester) async {
      await pumpScreen(tester, await seed());

      await openPicker(tester);

      expect(find.text('Export Sign Ups'), findsNWidgets(2)); // button + title
      expect(find.byType(AlertDialog), findsOneWidget);
      // (The hidden summary image behind the dialog lists every slot.)
      Finder inDialog(String label) => find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(label),
      );
      for (final label in ['Soon Seva', 'Later Seva', 'Empty Seva']) {
        expect(inDialog(label), findsOneWidget, reason: label);
      }
      expect(inDialog('Old Seva'), findsNothing);
    });

    testWidgets('shares an image of the entries of every ticked slot', (
      tester,
    ) async {
      final id = await seed();
      await pumpScreen(tester, id);

      await openPicker(tester);
      await confirmExport(tester);

      expect(capturedCards, hasLength(1));
      await showCapturedCard(tester);
      expect(find.text('Prasad Seva'), findsOneWidget);
      for (final name in ['Asha', 'Bhau', 'Bina']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('Soon Seva'), findsOneWidget); // its slot's title ...
      // ... and when it is (a SlotWhenView per slot; its wording depends on
      // the clock, so it is not matched here).
      expect(find.byType(SlotWhenView), findsNWidgets(2));
      expect(find.text('Pastor'), findsNothing); // a past slot
      expect(find.textContaining('example.com'), findsNothing);
      expect(find.textContaining('12065550100'), findsNothing);

      expect(shareCalls, hasLength(1));
      final args = shareCalls.single.arguments as Map<Object?, Object?>;
      final paths = (args['paths'] as List).cast<String>();
      expect(paths.single, endsWith('signup_entries_$id.png'));
      expect(File(paths.single).readAsBytesSync(), [1, 2, 3]);
      expect(args['text'], 'Prasad Seva');
    });

    testWidgets('leaves out the entries of slots that were unticked', (
      tester,
    ) async {
      await pumpScreen(tester, await seed());

      await openPicker(tester);
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Later Seva'));
      await tester.pump();
      await confirmExport(tester);

      await showCapturedCard(tester);
      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Bhau'), findsNothing);
      expect(find.text('Bina'), findsNothing);
    });

    /// Upcoming slots with [perSlot] entries each.
    Future<String> seedBusy({required int slots, required int perSlot}) async {
      final now = DateTime.now();
      final signup = await firestore.collection('signups').add({
        'titleEn': 'Busy Seva',
        'titleMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });
      for (var i = 0; i < slots; i++) {
        await addSlot(
          signup,
          'slot$i',
          'Seva $i',
          from: Duration(days: 3 + i),
          names: [for (var n = 0; n < perSlot; n++) 'Devotee $i-$n'],
        );
      }
      return signup.id;
    }

    List<String> sharedPaths() {
      final args = shareCalls.single.arguments as Map<Object?, Object?>;
      return (args['paths'] as List).cast<String>();
    }

    testWidgets('splits a long list over several images, shared together', (
      tester,
    ) async {
      final id = await seedBusy(slots: 3, perSlot: 30);
      await pumpScreen(tester, id);

      await openPicker(tester);
      await confirmExport(tester);

      expect(capturedCards.length, greaterThan(1));
      final total = capturedCards.length;
      expect(shareCalls, hasLength(1)); // one share sheet for all of them
      expect(sharedPaths(), [
        for (var i = 1; i <= total; i++)
          endsWith('signup_entries_${id}_$i.png'),
      ]);

      // Every devotee is on exactly one image, and each says which it is.
      final seen = <String>[];
      for (var i = 0; i < total; i++) {
        await showCapturedCard(tester, i);
        expect(find.text('Entries - Part ${i + 1} of $total'), findsOneWidget);
        for (final slot in [0, 1, 2]) {
          for (var n = 0; n < 30; n++) {
            if (find.text('Devotee $slot-$n').evaluate().isNotEmpty) {
              seen.add('Devotee $slot-$n');
            }
          }
        }
      }
      expect(seen, hasLength(90));
      expect(seen.toSet(), hasLength(90));
    });

    testWidgets('stops quietly when the screen is closed part-way through', (
      tester,
    ) async {
      final firstImage = Completer<Uint8List>();
      final logged = <String?>[];
      final original = debugPrint;
      var calls = 0;
      try {
        debugPrint = (message, {wrapWidth}) => logged.add(message);
        await pumpScreen(
          tester,
          await seedBusy(slots: 3, perSlot: 30),
          capture: (card, pixelRatio) {
            calls++;
            return calls == 1
                ? firstImage.future
                : Future.value(Uint8List.fromList([1]));
          },
        );

        await openPicker(tester);
        await tester.tap(find.widgetWithText(TextButton, 'Export'));
        await tester.pump();
        await tester.pumpWidget(const SizedBox()); // the admin leaves
        firstImage.complete(Uint8List.fromList([1]));
        // Give anything still going (a file write, a share) time to happen.
        for (var i = 0; i < 20; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
      } finally {
        debugPrint = original;
      }

      expect(tester.takeException(), isNull);
      expect(logged, isEmpty); // not even a logged failure
      expect(calls, 1); // no more images drawn for a screen that is gone
      expect(shareCalls, isEmpty);
    });

    testWidgets('draws a very long slot less sharply so it still fits', (
      tester,
    ) async {
      await pumpScreen(tester, await seedBusy(slots: 1, perSlot: 100));

      await openPicker(tester);
      await confirmExport(tester);

      expect(capturedRatios, hasLength(1));
      expect(capturedRatios.single, lessThan(2));
      expect(capturedRatios.single, greaterThanOrEqualTo(1));
    });

    testWidgets('draws a short list at full sharpness', (tester) async {
      await pumpScreen(tester, await seed());

      await openPicker(tester);
      await confirmExport(tester);

      expect(capturedRatios, [2]);
    });

    testWidgets('makes a real PNG of the table when nothing is stubbed', (
      tester,
    ) async {
      final id = await seed();
      await pumpScreen(tester, id, realCapture: true);

      await openPicker(tester);
      await confirmExport(tester);

      expect(find.text('Failed to export image'), findsNothing);
      final bytes = File(sharedPaths().single).readAsBytesSync();
      expect(bytes.sublist(1, 4), 'PNG'.codeUnits);
      final header = ByteData.sublistView(Uint8List.fromList(bytes));
      expect(header.getUint32(16), 840); // 420 dp card at ratio 2
      expect(header.getUint32(20), greaterThan(200));
    });

    testWidgets('names the group on the image', (tester) async {
      await pumpScreen(tester, await seed());

      await openPicker(tester);
      await confirmExport(tester);

      await showCapturedCard(tester);
      expect(find.text('Seattle'), findsOneWidget);
    });

    testWidgets('does nothing when the picker is cancelled', (tester) async {
      await pumpScreen(tester, await seed());

      await openPicker(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(capturedCards, isEmpty);
      expect(shareCalls, isEmpty);
    });

    testWidgets('says so, and shares nothing, when the ticked slots have no '
        'sign-ups', (tester) async {
      await pumpScreen(tester, await seed());

      await openPicker(tester);
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Select all'));
      await tester.pump();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Empty Seva'));
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Export'));
      await tester.pumpAndSettle();

      expect(
        find.text('The selected slots have no sign-ups yet.'),
        findsOneWidget,
      );
      expect(capturedCards, isEmpty);
      expect(shareCalls, isEmpty);
    });

    testWidgets('explains when there are no upcoming slots', (tester) async {
      final now = DateTime.now();
      final signup = await firestore.collection('signups').add({
        'titleEn': 'Done Seva',
        'titleMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });
      await addSlot(signup, 'old', 'Old Seva', from: const Duration(days: -5));
      await pumpScreen(tester, signup.id);

      await openPicker(tester);

      expect(
        find.text('There are no upcoming slots to export.'),
        findsOneWidget,
      );
    });

    testWidgets('shows a progress overlay while the image is made', (
      tester,
    ) async {
      final pending = Completer<Uint8List>();
      await pumpScreen(
        tester,
        await seed(),
        capture: (card, pixelRatio) => pending.future,
      );

      await openPicker(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Export'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete(Uint8List.fromList([1]));
      await settleRealIo(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(shareCalls, hasLength(1));
    });

    testWidgets('logs why making the image failed', (tester) async {
      final logged = <String?>[];
      final original = debugPrint;
      // Put back before the test ends: the framework checks it then.
      try {
        debugPrint = (message, {wrapWidth}) => logged.add(message);
        await pumpScreen(
          tester,
          await seed(),
          capture: (card, pixelRatio) async => throw Exception('render failed'),
        );

        await openPicker(tester);
        await tester.tap(find.widgetWithText(TextButton, 'Export'));
        await tester.pumpAndSettle();
      } finally {
        debugPrint = original;
      }

      expect(logged.join(), contains('render failed'));
    });

    testWidgets('shows an error, and lets the admin carry on, when making the '
        'image fails', (tester) async {
      await pumpScreen(
        tester,
        await seed(),
        capture: (card, pixelRatio) async => throw Exception('render failed'),
      );

      await openPicker(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Export'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to export image'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(shareCalls, isEmpty);
      // The button works again.
      await openPicker(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('shows an error when the image cannot be saved', (
      tester,
    ) async {
      PathProviderPlatform.instance = _ThrowingPathProviderPlatform();
      await pumpScreen(tester, await seed());

      await openPicker(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Export'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to export image'), findsOneWidget);
      expect(shareCalls, isEmpty);
    });
  });
}

import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_signup_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

class MockSignupService extends Mock implements SignupService {}

/// Mirrors the FakeImagePickerPlatform used in
/// admin_create_signup_sheet_screen_test.dart.
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
    required String sheetId,
    Map<String, WidgetBuilder>? routes,
    Locale locale = const Locale('en'),
  }) async {
    setLargeScreen(tester);
    addTearDown(() => resetScreen(tester));
    await tester.pumpWidget(
      createWidget(
        child: AdminSignupDetailScreen(
          sheetId: sheetId,
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
    testWidgets('renders not found state when sheet does not exist', (
      tester,
    ) async {
      await pumpDetailScreen(tester, sheetId: 'missing_sheet');
      expect(find.text('Sign up not found'), findsOneWidget);
    });

    testWidgets('tapping home icon pops until first route', (tester) async {
      await pumpDetailScreen(tester, sheetId: 'missing_sheet');

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
        sheetId: 'missing_sheet',
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

    testWidgets('renders sheet info, join code, and duplicate button', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
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

      await pumpDetailScreen(tester, sheetId: sheetRef.id);

      expect(find.text('Prasad Seva').first, findsOneWidget);
      expect(find.text('Help prepare prasad').first, findsOneWidget);
      expect(find.text('JOIN99'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Export Summary'), findsOneWidget);
    });

    testWidgets('copies join code to clipboard', (tester) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
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

      await pumpDetailScreen(tester, sheetId: sheetRef.id);

      await tester.tap(find.byTooltip('Copy Join Code'));
      await tester.pumpAndSettle();

      expect(find.text('Join Code copied to clipboard'), findsOneWidget);
    });

    testWidgets('unlocks and updates status to published', (tester) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
        'titleEn': 'Draft Sheet',
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

      await pumpDetailScreen(tester, sheetId: sheetRef.id);

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
          .doc(sheetRef.id)
          .get();
      expect(updated.data()?['status'], 'published');
      expect(find.text('Status updated successfully'), findsOneWidget);
    });

    testWidgets('duplicate button copies sheet and navigates to new draft', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
        'titleEn': 'Original Sheet',
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

      await sheetRef.collection('slots').add({
        'labelEn': 'Slot 1',
        'labelMr': 'स्लॉट १',
        'capacity': 3,
        'claimedCount': 2,
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(now),
      });

      String? navSheetId;
      await pumpDetailScreen(
        tester,
        sheetId: sheetRef.id,
        routes: {
          Routes.adminSignupSheetDetail: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            navSheetId = args?['sheetId'] as String?;
            return const Scaffold(body: Text('Duplicated Screen Mock'));
          },
        },
      );

      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();

      expect(navSheetId, isNotNull);
      expect(navSheetId, isNot(equals(sheetRef.id)));
      expect(find.text('Duplicated Screen Mock'), findsOneWidget);

      // Verify duplicate exists in Firestore as draft with 0 claimedCount
      final duplicateDoc = await firestore
          .collection('signups')
          .doc(navSheetId)
          .get();
      expect(duplicateDoc.data()?['status'], 'draft');
      expect(duplicateDoc.data()?['titleEn'], 'Original Sheet');

      final duplicateSlots = await firestore
          .collection('signups')
          .doc(navSheetId)
          .collection('slots')
          .get();
      expect(duplicateSlots.docs.length, 1);
      expect(duplicateSlots.docs.first.data()['claimedCount'], 0);
    });

    testWidgets('manually adds an entry to a slot via dialog', (tester) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
        'titleEn': 'Sheet 1',
        'titleMr': 'शीट १',
        'descriptionEn': '',
        'descriptionMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      final slotRef = await sheetRef.collection('slots').add({
        'labelEn': 'Morning Seva',
        'labelMr': 'सकाळची सेवा',
        'capacity': 3,
        'claimedCount': 0,
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(now),
      });

      await pumpDetailScreen(tester, sheetId: sheetRef.id);

      expect(find.text('Morning Seva').first, findsOneWidget);
      expect(find.text('Add Devotee'), findsOneWidget);

      await tester.tap(find.text('Add Devotee'));
      await tester.pumpAndSettle();

      expect(find.text('Add Devotee Entry'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('entryNameField')),
        'Ram Das',
      );
      await tester.enterText(
        find.byKey(const Key('entryPhoneField')),
        '5551234',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Devotee added successfully'), findsOneWidget);
      expect(find.text('Ram Das'), findsOneWidget);

      // Verify slot claimedCount incremented
      final slotDoc = await slotRef.get();
      expect(slotDoc.data()?['claimedCount'], 1);
    });

    testWidgets('edits and removes an entry', (tester) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
        'titleEn': 'Sheet 1',
        'titleMr': 'शीट १',
        'descriptionEn': '',
        'descriptionMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      final slotRef = await sheetRef.collection('slots').add({
        'labelEn': 'Morning Seva',
        'labelMr': 'सकाळची सेवा',
        'capacity': 3,
        'claimedCount': 1,
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(now),
      });

      await sheetRef.collection('entries').add({
        'slotId': slotRef.id,
        'name': 'Old Name',
        'phone': '1112223333',
        'joinedAt': Timestamp.fromDate(now),
      });

      await pumpDetailScreen(tester, sheetId: sheetRef.id);

      expect(find.text('Old Name'), findsOneWidget);

      // Tap Edit
      await tester.tap(find.byTooltip('Edit Entry'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('entryNameField')),
        'New Name',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Entry updated successfully'), findsOneWidget);
      expect(find.text('New Name'), findsOneWidget);

      // Tap Remove
      await tester.tap(find.byTooltip('Remove Entry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to remove this entry?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.text('Entry removed successfully'), findsOneWidget);
      expect(find.text('New Name'), findsNothing);

      // Verify slot claimedCount decremented to 0
      final slotDoc = await slotRef.get();
      expect(slotDoc.data()?['claimedCount'], 0);
    });

    testWidgets('renders Marathi localized strings when locale is mr', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
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
        sheetId: sheetRef.id,
        locale: const Locale('mr'),
      );

      expect(find.text('साइन अप डिटेल्स'), findsOneWidget);
      expect(find.text('प्रसाद सेवा').first, findsOneWidget);
      expect(find.text('मदत').first, findsOneWidget);
      expect(find.text('डुप्लीकेट करा'), findsOneWidget);
      expect(find.text('शेअर'), findsOneWidget);
      await tester.tap(find.text('शेअर'));
      await tester.pumpAndSettle();
      expect(find.text('स्लॉट्स आणि एंट्रीज'), findsOneWidget);
    });

    testWidgets('falls back to the English description when Marathi is blank', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
        'titleEn': 'Prasad Seva',
        'titleMr': 'प्रसाद सेवा',
        'descriptionEn': 'Help cook prasad',
        'descriptionMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.draft.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      await pumpDetailScreen(
        tester,
        sheetId: sheetRef.id,
        locale: const Locale('mr'),
      );

      expect(find.text('Help cook prasad').first, findsOneWidget);
    });

    testWidgets('shows slot full error when admin adds entry to full slot', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
        'titleEn': 'Full Sheet',
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

      await sheetRef.collection('slots').add({
        'labelEn': 'Slot 1',
        'labelMr': 'स्लॉट १',
        'capacity': 1,
        'claimedCount': 1, // already full!
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(now),
      });

      await pumpDetailScreen(tester, sheetId: sheetRef.id);

      await tester.tap(find.text('Add Devotee'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('entryNameField')),
        'New Devotee',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('This slot is already full'), findsOneWidget);
    });

    testWidgets('shows error snackbar when duplicateSheet throws', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheet = Signup(
        id: 'sheet_err',
        titleEn: 'Error Sheet',
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
        () => mockService.getSheetById('sheet_err'),
      ).thenAnswer((_) => Stream.value(sheet));
      when(
        () => mockService.getSlots('sheet_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getAllEntries('sheet_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.duplicateSheet('sheet_err'),
      ).thenThrow(Exception('Firestore error'));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            sheetId: 'sheet_err',
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

    testWidgets('shows error snackbar when updateSheetStatus throws', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheet = Signup(
        id: 'sheet_status_err',
        titleEn: 'Status Error Sheet',
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
        () => mockService.getSheetById('sheet_status_err'),
      ).thenAnswer((_) => Stream.value(sheet));
      when(
        () => mockService.getSlots('sheet_status_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getAllEntries('sheet_status_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.updateSheetStatus('sheet_status_err', any()),
      ).thenThrow(Exception('Network error'));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            sheetId: 'sheet_status_err',
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
        final sheetRef = await firestore.collection('signups').add({
          'titleEn': 'Route Args Sheet',
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
                          name: Routes.adminSignupSheetDetail,
                          arguments: {
                            'sheetId': sheetRef.id,
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

        expect(find.text('Route Args Sheet').first, findsOneWidget);
      },
    );

    testWidgets('cancels remove entry dialog when No is clicked', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
        'titleEn': 'Cancel Remove Sheet',
        'titleMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      final slotRef = await sheetRef.collection('slots').add({
        'titleEn': 'Slot 1',
        'titleMr': '',
        'maxCapacity': 5,
        'order': 0,
      });

      await sheetRef.collection('entries').add({
        'slotId': slotRef.id,
        'name': 'Stay Put User',
        'phone': '1112223333',
        'createdAt': Timestamp.fromDate(now),
        'status': 'confirmed',
      });

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            sheetId: sheetRef.id,
            adminUser: adminUser,
            firestore: firestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stay Put User'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove Entry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to remove this entry?'),
        findsOneWidget,
      );

      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to remove this entry?'),
        findsNothing,
      );
      expect(find.text('Stay Put User'), findsOneWidget);
    });

    testWidgets('shows error snackbar when adminRemoveEntry fails', (
      tester,
    ) async {
      final now = DateTime.now();
      const sheetId = 'fail_remove_sheet';
      const slotId = 'slot_1';
      const entryId = 'entry_1';
      final sheet = Signup(
        id: sheetId,
        titleEn: 'Fail Remove Sheet',
        titleMr: '',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupStatus.published,
        requiresJoinCode: false,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      );
      final slot = SignupSlot(
        id: slotId,
        labelEn: 'Slot 1',
        labelMr: '',
        capacity: 5,
        sortOrder: 0,
        createdAt: now,
      );
      final entry = SignupEntry(
        id: entryId,
        slotId: slotId,
        name: 'Fail Remove User',
        phone: '1112223333',
        joinedAt: now,
      );

      final mockService = MockSignupService();
      when(
        () => mockService.getSheetById(sheetId),
      ).thenAnswer((_) => Stream.value(sheet));
      when(
        () => mockService.getSlots(sheetId),
      ).thenAnswer((_) => Stream.value([slot]));
      when(
        () => mockService.getAllEntries(sheetId),
      ).thenAnswer((_) => Stream.value([entry]));
      when(
        () => mockService.adminRemoveEntry(sheetId, entryId),
      ).thenThrow(Exception('Delete failed'));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            sheetId: sheetId,
            adminUser: adminUser,
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Remove Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to remove entry'), findsOneWidget);
    });

    testWidgets('shows error snackbar when updateEntry fails', (tester) async {
      final now = DateTime.now();
      const sheetId = 'fail_update_sheet';
      const slotId = 'slot_1';
      const entryId = 'entry_1';
      final sheet = Signup(
        id: sheetId,
        titleEn: 'Fail Update Sheet',
        titleMr: '',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupStatus.published,
        requiresJoinCode: false,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      );
      final slot = SignupSlot(
        id: slotId,
        labelEn: 'Slot 1',
        labelMr: '',
        capacity: 5,
        sortOrder: 0,
        createdAt: now,
      );
      final entry = SignupEntry(
        id: entryId,
        slotId: slotId,
        name: 'Fail Update User',
        phone: '1112223333',
        joinedAt: now,
      );

      final mockService = MockSignupService();
      when(
        () => mockService.getSheetById(sheetId),
      ).thenAnswer((_) => Stream.value(sheet));
      when(
        () => mockService.getSlots(sheetId),
      ).thenAnswer((_) => Stream.value([slot]));
      when(
        () => mockService.getAllEntries(sheetId),
      ).thenAnswer((_) => Stream.value([entry]));
      when(
        () => mockService.updateEntry(sheetId, any()),
      ).thenThrow(Exception('Update failed'));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            sheetId: sheetId,
            adminUser: adminUser,
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to update entry'), findsOneWidget);
    });

    testWidgets(
      'shows error snackbar when adminAddEntry throws generic error',
      (tester) async {
        final now = DateTime.now();
        const sheetId = 'fail_add_sheet';
        const slotId = 'slot_1';
        final sheet = Signup(
          id: sheetId,
          titleEn: 'Fail Add Sheet',
          titleMr: '',
          groupId: 'gajanan_maharaj_seattle',
          status: SignupStatus.published,
          requiresJoinCode: false,
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin@test.com',
        );
        final slot = SignupSlot(
          id: slotId,
          labelEn: 'Slot 1',
          labelMr: '',
          capacity: 5,
          sortOrder: 0,
          createdAt: now,
        );

        final mockService = MockSignupService();
        when(
          () => mockService.getSheetById(sheetId),
        ).thenAnswer((_) => Stream.value(sheet));
        when(
          () => mockService.getSlots(sheetId),
        ).thenAnswer((_) => Stream.value([slot]));
        when(
          () => mockService.getAllEntries(sheetId),
        ).thenAnswer((_) => Stream.value(const []));
        when(
          () => mockService.adminAddEntry(
            sheetId: any(named: 'sheetId'),
            slotId: any(named: 'slotId'),
            name: any(named: 'name'),
            phone: null,
            email: null,
            pledgeAmount: null,
            note: null,
          ),
        ).thenAnswer((_) async => {'success': false, 'error': 'generic_error'});

        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));

        await tester.pumpWidget(
          createWidget(
            child: AdminSignupDetailScreen(
              sheetId: sheetId,
              adminUser: adminUser,
              signupService: mockService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add Devotee'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('entryNameField')),
          'Test Person',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to add devotee'), findsOneWidget);
      },
    );

    testWidgets('triggers deep link share when share button is tapped', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
        'titleEn': 'Shareable Sheet',
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
            sheetId: sheetRef.id,
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
      final sheetRef = await firestore.collection('signups').add({
        'titleEn': 'Exportable Sheet',
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
            sheetId: sheetRef.id,
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
        final sheetRef = await firestore.collection('signups').add({
          'titleEn': 'Exportable Sheet',
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
              sheetId: sheetRef.id,
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
      const sheetId = 'processing_sheet';
      final sheet = Signup(
        id: sheetId,
        titleEn: 'Processing Sheet',
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
        () => mockService.getSheetById(sheetId),
      ).thenAnswer((_) => Stream.value(sheet));
      when(
        () => mockService.getSlots(sheetId),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getAllEntries(sheetId),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.duplicateSheet(sheetId),
      ).thenAnswer((_) => completer.future);

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            sheetId: sheetId,
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

    testWidgets(
      'deleting from within edit dialog triggers confirm remove dialog',
      (tester) async {
        final now = DateTime.now();
        final sheetRef = await firestore.collection('signups').add({
          'titleEn': 'Dialog Delete Sheet',
          'titleMr': '',
          'groupId': 'gajanan_maharaj_seattle',
          'status': SignupStatus.published.name,
          'requiresJoinCode': false,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'createdBy': 'admin@test.com',
        });

        final slotRef = await sheetRef.collection('slots').add({
          'labelEn': 'Slot 1',
          'labelMr': '',
          'capacity': 5,
          'sortOrder': 0,
          'createdAt': Timestamp.fromDate(now),
        });

        await sheetRef.collection('entries').add({
          'slotId': slotRef.id,
          'name': 'Dialog Delete User',
          'phone': '1112223333',
          'joinedAt': Timestamp.fromDate(now),
        });

        await pumpDetailScreen(tester, sheetId: sheetRef.id);

        await tester.tap(find.byTooltip('Edit Entry'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Remove Entry'));
        await tester.pumpAndSettle();

        expect(
          find.text('Are you sure you want to remove this entry?'),
          findsOneWidget,
        );

        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('shows error snackbar when adminAddEntry throws exception', (
      tester,
    ) async {
      final now = DateTime.now();
      const sheetId = 'fail_add_exc_sheet';
      const slotId = 'slot_1';
      final sheet = Signup(
        id: sheetId,
        titleEn: 'Fail Add Sheet',
        titleMr: '',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupStatus.published,
        requiresJoinCode: false,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      );
      final slot = SignupSlot(
        id: slotId,
        labelEn: 'Slot 1',
        labelMr: '',
        capacity: 5,
        sortOrder: 0,
        createdAt: now,
      );

      final mockService = MockSignupService();
      when(
        () => mockService.getSheetById(sheetId),
      ).thenAnswer((_) => Stream.value(sheet));
      when(
        () => mockService.getSlots(sheetId),
      ).thenAnswer((_) => Stream.value([slot]));
      when(
        () => mockService.getAllEntries(sheetId),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.adminAddEntry(
          sheetId: any(named: 'sheetId'),
          slotId: any(named: 'slotId'),
          name: any(named: 'name'),
          phone: null,
          email: null,
          pledgeAmount: null,
          note: null,
        ),
      ).thenAnswer((_) => Future.error(Exception('Crash on add')));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            sheetId: sheetId,
            adminUser: adminUser,
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Devotee'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('entryNameField')),
        'Test Person',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to add devotee'), findsOneWidget);
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

    Future<String> seedSheet({String? headerImageUrl}) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signups').add({
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
      return sheetRef.id;
    }

    testWidgets('shows Add Image when the sheet has no image', (tester) async {
      final sheetId = await seedSheet();

      await pumpDetailScreen(tester, sheetId: sheetId);

      expect(find.text('Add Image'), findsOneWidget);
      expect(find.text('Replace Image'), findsNothing);
      expect(find.text('Remove Image'), findsNothing);
    });

    testWidgets(
      'shows a preview and Replace/Remove when the sheet has an image',
      (tester) async {
        final sheetId = await seedSheet(
          headerImageUrl: 'https://example.com/header.jpg',
        );

        await pumpDetailScreen(tester, sheetId: sheetId);
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
      final sheetId = await seedSheet();

      await pumpDetailScreen(tester, sheetId: sheetId);
      await tester.tap(find.byKey(const Key('addOrReplaceHeaderImageButton')));
      await tester.pumpAndSettle();
      drainNetworkImageErrors(tester);

      final doc = await firestore.collection('signups').doc(sheetId).get();
      expect(doc.data()?['headerImageUrl'], isNotNull);
      expect(
        storage.storedDataMap.containsKey('signups/$sheetId/header'),
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
      final sheetId = await seedSheet();

      await pumpDetailScreen(tester, sheetId: sheetId);
      await tester.tap(find.byKey(const Key('addOrReplaceHeaderImageButton')));
      await tester.pumpAndSettle();

      expect(find.text('Image must be smaller than 2 MB'), findsOneWidget);
      expect(find.text('Add Image'), findsOneWidget);
    });

    testWidgets('shows an error snackbar when the upload fails', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheet = Signup(
        id: 'sheet_img_err',
        titleEn: 'Error Sheet',
        titleMr: 'त्रुटी शीट',
        groupId: 'gajanan_maharaj_seattle',
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      );
      final mockService = MockSignupService();
      when(
        () => mockService.getSheetById('sheet_img_err'),
      ).thenAnswer((_) => Stream.value(sheet));
      when(
        () => mockService.getSlots('sheet_img_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getAllEntries('sheet_img_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.uploadHeaderImage(
          sheetId: any(named: 'sheetId'),
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
            sheetId: 'sheet_img_err',
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
      final sheetId = await seedSheet(
        headerImageUrl: 'https://example.com/header.jpg',
      );

      await pumpDetailScreen(tester, sheetId: sheetId);
      drainNetworkImageErrors(tester);
      await tester.tap(find.byKey(const Key('removeHeaderImageButton')));
      await tester.pumpAndSettle();

      expect(find.text('Remove Image?'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      drainNetworkImageErrors(tester);

      final doc = await firestore.collection('signups').doc(sheetId).get();
      expect(doc.data()?['headerImageUrl'], 'https://example.com/header.jpg');
    });

    testWidgets('confirming removal clears headerImageUrl', (tester) async {
      final sheetId = await seedSheet(
        headerImageUrl: 'https://example.com/header.jpg',
      );

      await pumpDetailScreen(tester, sheetId: sheetId);
      drainNetworkImageErrors(tester);
      await tester.tap(find.byKey(const Key('removeHeaderImageButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      final doc = await firestore.collection('signups').doc(sheetId).get();
      expect(doc.data()?['headerImageUrl'], isNull);
      expect(find.text('Add Image'), findsOneWidget);
    });

    testWidgets(
      'hides add/replace/remove buttons while a removal is in flight',
      (tester) async {
        final now = DateTime.now();
        final sheet = Signup(
          id: 'sheet_removing',
          titleEn: 'Removing Sheet',
          titleMr: 'काढत आहे',
          groupId: 'gajanan_maharaj_seattle',
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin@test.com',
          headerImageUrl: 'https://example.com/header.jpg',
        );
        final mockService = MockSignupService();
        when(
          () => mockService.getSheetById('sheet_removing'),
        ).thenAnswer((_) => Stream.value(sheet));
        when(
          () => mockService.getSlots('sheet_removing'),
        ).thenAnswer((_) => Stream.value(const []));
        when(
          () => mockService.getAllEntries('sheet_removing'),
        ).thenAnswer((_) => Stream.value(const []));
        final removeCompleter = Completer<void>();
        when(
          () => mockService.removeHeaderImage('sheet_removing'),
        ).thenAnswer((_) => removeCompleter.future);

        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));
        await tester.pumpWidget(
          createWidget(
            child: AdminSignupDetailScreen(
              sheetId: 'sheet_removing',
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
      final sheet = Signup(
        id: 'sheet_remove_err',
        titleEn: 'Error Sheet',
        titleMr: 'त्रुटी शीट',
        groupId: 'gajanan_maharaj_seattle',
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
        headerImageUrl: 'https://example.com/header.jpg',
      );
      final mockService = MockSignupService();
      when(
        () => mockService.getSheetById('sheet_remove_err'),
      ).thenAnswer((_) => Stream.value(sheet));
      when(
        () => mockService.getSlots('sheet_remove_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getAllEntries('sheet_remove_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.removeHeaderImage('sheet_remove_err'),
      ).thenThrow(Exception('remove failed'));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));
      await tester.pumpWidget(
        createWidget(
          child: AdminSignupDetailScreen(
            sheetId: 'sheet_remove_err',
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
}

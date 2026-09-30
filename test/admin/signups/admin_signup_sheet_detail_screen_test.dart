import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_signup_sheet_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

class MockSignupService extends Mock implements SignupService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminUser adminUser;
  late MockAppConfigProvider appConfigProvider;

  setUpAll(() {
    registerFallbackValue(SignupSheetStatus.published);
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
        child: AdminSignupSheetDetailScreen(
          sheetId: sheetId,
          adminUser: adminUser,
          firestore: firestore,
        ),
        routes: routes,
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AdminSignupSheetDetailScreen', () {
    testWidgets('renders not found state when sheet does not exist', (
      tester,
    ) async {
      await pumpDetailScreen(tester, sheetId: 'missing_sheet');
      expect(find.text('Sign-up sheet not found'), findsOneWidget);
    });

    testWidgets('renders sheet info, join code, and duplicate button', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signup_sheets').add({
        'titleEn': 'Prasad Seva',
        'titleMr': 'प्रसाद सेवा',
        'descriptionEn': 'Help prepare prasad',
        'descriptionMr': 'प्रसाद बनवण्यासाठी मदत',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupSheetStatus.draft.name,
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
      expect(find.text('Duplicate Sheet'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Export Summary'), findsOneWidget);
    });

    testWidgets('copies join code to clipboard', (tester) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signup_sheets').add({
        'titleEn': 'Prasad Seva',
        'titleMr': 'प्रसाद सेवा',
        'descriptionEn': 'Description',
        'descriptionMr': 'वर्णन',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupSheetStatus.published.name,
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
      final sheetRef = await firestore.collection('signup_sheets').add({
        'titleEn': 'Draft Sheet',
        'titleMr': 'मसुदा',
        'descriptionEn': 'Draft',
        'descriptionMr': 'मसुदा',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupSheetStatus.draft.name,
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
          .collection('signup_sheets')
          .doc(sheetRef.id)
          .get();
      expect(updated.data()?['status'], 'published');
      expect(find.text('Status updated successfully'), findsOneWidget);
    });

    testWidgets('duplicate button copies sheet and navigates to new draft', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signup_sheets').add({
        'titleEn': 'Original Sheet',
        'titleMr': 'मूळ शीट',
        'descriptionEn': 'Desc',
        'descriptionMr': 'वर्णन',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupSheetStatus.published.name,
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

      await tester.tap(find.text('Duplicate Sheet'));
      await tester.pumpAndSettle();

      expect(navSheetId, isNotNull);
      expect(navSheetId, isNot(equals(sheetRef.id)));
      expect(find.text('Duplicated Screen Mock'), findsOneWidget);

      // Verify duplicate exists in Firestore as draft with 0 claimedCount
      final duplicateDoc = await firestore
          .collection('signup_sheets')
          .doc(navSheetId)
          .get();
      expect(duplicateDoc.data()?['status'], 'draft');
      expect(duplicateDoc.data()?['titleEn'], 'Original Sheet');

      final duplicateSlots = await firestore
          .collection('signup_sheets')
          .doc(navSheetId)
          .collection('slots')
          .get();
      expect(duplicateSlots.docs.length, 1);
      expect(duplicateSlots.docs.first.data()['claimedCount'], 0);
    });

    testWidgets('manually adds an entry to a slot via dialog', (tester) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signup_sheets').add({
        'titleEn': 'Sheet 1',
        'titleMr': 'शीट १',
        'descriptionEn': '',
        'descriptionMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupSheetStatus.published.name,
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
      final sheetRef = await firestore.collection('signup_sheets').add({
        'titleEn': 'Sheet 1',
        'titleMr': 'शीट १',
        'descriptionEn': '',
        'descriptionMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupSheetStatus.published.name,
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
      final sheetRef = await firestore.collection('signup_sheets').add({
        'titleEn': 'Prasad Seva',
        'titleMr': 'प्रसाद सेवा',
        'descriptionEn': 'Help',
        'descriptionMr': 'मदत',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupSheetStatus.draft.name,
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

      expect(find.text('साइन-अप शीट तपशील'), findsOneWidget);
      expect(find.text('प्रसाद सेवा').first, findsOneWidget);
      expect(find.text('मदत').first, findsOneWidget);
      expect(find.text('शीटची प्रत तयार करा'), findsOneWidget);
      expect(find.text('शेअर करा'), findsOneWidget);
      await tester.tap(find.text('शेअर करा'));
      await tester.pumpAndSettle();
      expect(find.text('स्लॉट्स आणि नोंदी'), findsOneWidget);
    });

    testWidgets('shows slot full error when admin adds entry to full slot', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signup_sheets').add({
        'titleEn': 'Full Sheet',
        'titleMr': 'शीट',
        'descriptionEn': '',
        'descriptionMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupSheetStatus.published.name,
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
      final sheet = SignupSheet(
        id: 'sheet_err',
        titleEn: 'Error Sheet',
        titleMr: 'त्रुटी शीट',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupSheetStatus.draft,
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
          child: AdminSignupSheetDetailScreen(
            sheetId: 'sheet_err',
            adminUser: adminUser,
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duplicate Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to duplicate sheet'), findsOneWidget);
    });

    testWidgets('shows error snackbar when updateSheetStatus throws', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheet = SignupSheet(
        id: 'sheet_status_err',
        titleEn: 'Status Error Sheet',
        titleMr: 'शीट',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupSheetStatus.draft,
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
          child: AdminSignupSheetDetailScreen(
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
        final sheetRef = await firestore.collection('signup_sheets').add({
          'titleEn': 'Route Args Sheet',
          'titleMr': 'शीट',
          'descriptionEn': '',
          'descriptionMr': '',
          'groupId': 'gajanan_maharaj_seattle',
          'status': SignupSheetStatus.published.name,
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
                            AdminSignupSheetDetailScreen(firestore: firestore),
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
      final sheetRef = await firestore.collection('signup_sheets').add({
        'titleEn': 'Cancel Remove Sheet',
        'titleMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupSheetStatus.published.name,
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
          child: AdminSignupSheetDetailScreen(
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
      final sheet = SignupSheet(
        id: sheetId,
        titleEn: 'Fail Remove Sheet',
        titleMr: '',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupSheetStatus.published,
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
          child: AdminSignupSheetDetailScreen(
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
      final sheet = SignupSheet(
        id: sheetId,
        titleEn: 'Fail Update Sheet',
        titleMr: '',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupSheetStatus.published,
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
          child: AdminSignupSheetDetailScreen(
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
        final sheet = SignupSheet(
          id: sheetId,
          titleEn: 'Fail Add Sheet',
          titleMr: '',
          groupId: 'gajanan_maharaj_seattle',
          status: SignupSheetStatus.published,
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
            child: AdminSignupSheetDetailScreen(
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
      final sheetRef = await firestore.collection('signup_sheets').add({
        'titleEn': 'Shareable Sheet',
        'titleMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupSheetStatus.published.name,
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
          child: AdminSignupSheetDetailScreen(
            sheetId: sheetRef.id,
            adminUser: adminUser,
            firestore: firestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Share'));
      await tester.pumpAndSettle();
    });

    testWidgets('triggers export summary when export button is tapped', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetRef = await firestore.collection('signup_sheets').add({
        'titleEn': 'Exportable Sheet',
        'titleMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupSheetStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupSheetDetailScreen(
            sheetId: sheetRef.id,
            adminUser: adminUser,
            firestore: firestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Export Summary'));
      await tester.pumpAndSettle();
    });

    testWidgets('shows loading overlay when isProcessing is true', (
      tester,
    ) async {
      final now = DateTime.now();
      const sheetId = 'processing_sheet';
      final sheet = SignupSheet(
        id: sheetId,
        titleEn: 'Processing Sheet',
        titleMr: '',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupSheetStatus.draft,
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
          child: AdminSignupSheetDetailScreen(
            sheetId: sheetId,
            adminUser: adminUser,
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duplicate Sheet'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete('new_id');
      await tester.pumpAndSettle();
    });

    testWidgets(
      'deleting from within edit dialog triggers confirm remove dialog',
      (tester) async {
        final now = DateTime.now();
        final sheetRef = await firestore.collection('signup_sheets').add({
          'titleEn': 'Dialog Delete Sheet',
          'titleMr': '',
          'groupId': 'gajanan_maharaj_seattle',
          'status': SignupSheetStatus.published.name,
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
      final sheet = SignupSheet(
        id: sheetId,
        titleEn: 'Fail Add Sheet',
        titleMr: '',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupSheetStatus.published,
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
          child: AdminSignupSheetDetailScreen(
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
}

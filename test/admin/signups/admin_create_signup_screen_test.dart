import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_create_signup_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

class MockSignupService extends Mock implements SignupService {}

/// A real, decodable 1x1 transparent PNG - Image.memory() actually decodes
/// the picked bytes to render a preview, so arbitrary filler bytes aren't
/// enough; this is the smallest valid file that will do.
final Uint8List _validPngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]);

/// Stands in for the real platform channel so tests can control exactly
/// what `ImagePicker().pickImage(...)` returns, mirroring the
/// PathProviderPlatform fake-subclass pattern used elsewhere in this project.
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

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseStorage storage;
  late AdminUser adminUser;
  late MockAppConfigProvider appConfigProvider;

  setUpAll(() {
    registerFallbackValue(
      Signup(
        titleEn: 'dummy',
        titleMr: 'dummy',
        groupId: 'dummy',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        createdBy: 'dummy',
      ),
    );
    registerFallbackValue(<SignupSlot>[]);
    registerFallbackValue(Uint8List(0));
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
      gajananMaharajGroups: const [],
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

  Widget createWidget(Widget child) {
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
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

  Future<void> pumpScreen(WidgetTester tester) async {
    setLargeScreen(tester);
    addTearDown(() => resetScreen(tester));
    await tester.pumpWidget(
      createWidget(
        AdminCreateSignupScreen(
          adminUser: adminUser,
          firestore: firestore,
          storage: storage,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Picks today's date for slot [index] through the date picker (the date
  /// is mandatory, so any test that saves successfully needs one).
  Future<void> pickSlotDate(WidgetTester tester, [int index = 0]) async {
    await tester.tap(find.byKey(Key('slotStartDate_$index')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  /// Opens the date picker from [button] and picks [target]. The picker opens
  /// on the month of [openedOn] (the date the button currently holds), so it
  /// is paged forward from there.
  Future<void> pickDate(
    WidgetTester tester,
    Key button, {
    required DateTime openedOn,
    required DateTime target,
  }) async {
    await tester.tap(find.byKey(button));
    await tester.pumpAndSettle();
    final months =
        (target.year - openedOn.year) * 12 + target.month - openedOn.month;
    for (var i = 0; i < months; i++) {
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('${target.day}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  /// Picks a time in the time picker opened from [button], accepting the time
  /// it opens on.
  Future<void> acceptTime(WidgetTester tester, Key button) async {
    await tester.tap(find.byKey(button));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> fillFirstSlot(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
    await tester.tap(find.text('Add Slot'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'L');
    await tester.enterText(find.byKey(const Key('slotCapacity_0')), '2');
  }

  Future<Map<String, dynamic>> onlySlot() async {
    final signup = (await firestore.collection('signups').get()).docs.single;
    return (await signup.reference.collection('slots').get()).docs.single
        .data();
  }

  DateTime instantOf(Map<String, dynamic> slot, String field) =>
      (slot[field] as Timestamp).toDate().toUtc();

  group('AdminCreateSignupScreen', () {
    testWidgets(
      'renders title/description fields, join code toggle, and empty slot state',
      (tester) async {
        await pumpScreen(tester);

        expect(find.text('Title (English)'), findsOneWidget);
        expect(find.text('Title (Marathi, optional)'), findsOneWidget);
        expect(find.text('Description (English)'), findsOneWidget);
        expect(find.text('Description (Marathi, optional)'), findsOneWidget);
        expect(find.text('Require a join code to sign up'), findsOneWidget);
        expect(find.text('Add Slot'), findsOneWidget);
        expect(
          find.text('No slots yet. Tap "Add Slot" to create one.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('validation fails when title and slots are missing', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter English title'), findsOneWidget);
      expect(find.text('Please add at least one slot'), findsOneWidget);
    });

    testWidgets('Marathi title is optional and does not block saving', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(const Key('titleEnField')),
        'Prasad Seva',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter English title'), findsNothing);
      expect(find.text('Please add at least one slot'), findsOneWidget);
    });

    testWidgets('tapping Add Slot adds a row with its own required fields', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();

      expect(
        find.text('No slots yet. Tap "Add Slot" to create one.'),
        findsNothing,
      );
      expect(find.text('Slot Label (English)'), findsOneWidget);
      expect(find.text('Slot Label (Marathi, optional)'), findsOneWidget);
      expect(find.text('Capacity'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an English label'), findsOneWidget);
      expect(find.text('Please enter a capacity'), findsOneWidget);
    });

    testWidgets('Marathi slot label is optional and does not block saving', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'Morning');
      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '5');
      await pickSlotDate(tester);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an English label'), findsNothing);
      expect(find.text('Please enter a capacity'), findsNothing);
    });

    testWidgets('removing a slot removes its row', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove slot'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove slot'));
      await tester.pumpAndSettle();

      expect(
        find.text('No slots yet. Tap "Add Slot" to create one.'),
        findsOneWidget,
      );
    });

    testWidgets('moving a slot up swaps its position with the previous one', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'First');

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('slotLabelEn_1')), 'Second');

      await tester.tap(find.byTooltip('Move slot up').last);
      await tester.pumpAndSettle();

      final firstRowField = tester.widget<TextFormField>(
        find.byKey(const Key('slotLabelEn_0')),
      );
      final secondRowField = tester.widget<TextFormField>(
        find.byKey(const Key('slotLabelEn_1')),
      );
      expect(firstRowField.controller!.text, 'Second');
      expect(secondRowField.controller!.text, 'First');
    });

    testWidgets('moving a slot down swaps its position with the next one', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'First');

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('slotLabelEn_1')), 'Second');

      await tester.tap(find.byTooltip('Move slot down').first);
      await tester.pumpAndSettle();

      final firstRowField = tester.widget<TextFormField>(
        find.byKey(const Key('slotLabelEn_0')),
      );
      final secondRowField = tester.widget<TextFormField>(
        find.byKey(const Key('slotLabelEn_1')),
      );
      expect(firstRowField.controller!.text, 'Second');
      expect(secondRowField.controller!.text, 'First');
    });

    testWidgets('rejects a zero or non-numeric capacity', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '0');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Capacity must be a positive number'), findsOneWidget);
    });

    testWidgets('rejects a non-numeric suggested amount', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('slotSuggestedAmount_0')),
        'twenty dollars',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid amount'), findsOneWidget);
    });

    testWidgets('accepts a valid numeric suggested amount and persists it', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
      await tester.enterText(find.byKey(const Key('titleMrField')), 'T');
      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'L');
      await tester.enterText(find.byKey(const Key('slotLabelMr_0')), 'L');
      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '1');
      await pickSlotDate(tester);
      await tester.enterText(
        find.byKey(const Key('slotSuggestedAmount_0')),
        '50.5',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid amount'), findsNothing);
      final signups = await firestore.collection('signups').get();
      final slots = await firestore
          .collection('signups')
          .doc(signups.docs.first.id)
          .collection('slots')
          .get();
      expect(slots.docs.first.data()['suggestedAmount'], 50.5);
    });

    testWidgets('picking a start date fills the start and end buttons', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('slotStartDate_0')),
          matching: find.text('Select Date'),
        ),
        findsOneWidget,
      );

      await pickSlotDate(tester);

      expect(find.text('Select Date'), findsNothing);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('a slot without a date blocks saving and creates nothing', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'L');
      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '2');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please select a date'), findsOneWidget);
      expect((await firestore.collection('signups').get()).docs, isEmpty);
    });

    testWidgets('the date error clears once a date is picked', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'L');
      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '2');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Please select a date'), findsOneWidget);

      await pickSlotDate(tester);

      expect(find.text('Please select a date'), findsNothing);
    });

    testWidgets('every slot needs its own date', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(Key('slotLabelEn_$i')), 'L$i');
        await tester.enterText(find.byKey(Key('slotCapacity_$i')), '2');
      }
      await pickSlotDate(tester); // only the first slot

      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please select a date'), findsOneWidget);
      expect((await firestore.collection('signups').get()).docs, isEmpty);
    });

    testWidgets('scrolls to a slot date error that is off screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        createWidget(
          AdminCreateSignupScreen(
            adminUser: adminUser,
            firestore: firestore,
            storage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
      for (var i = 0; i < 3; i++) {
        await tester.ensureVisible(find.text('Add Slot'));
        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(Key('slotLabelEn_$i')));
        await tester.enterText(find.byKey(Key('slotLabelEn_$i')), 'L$i');
        await tester.enterText(find.byKey(Key('slotCapacity_$i')), '2');
      }
      await tester.ensureVisible(find.text('Save'));

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final error = find.text('Please select a date').first;
      expect(error, findsOneWidget);
      final rect = tester.getRect(error);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(700));
    });

    testWidgets(
      'shows an error and creates nothing when the admin has no groupId',
      (tester) async {
        adminUser = const AdminUser(
          email: 'admin@test.com',
          roles: ['group_admin'],
        );
        await pumpScreen(tester);

        await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
        await tester.enterText(find.byKey(const Key('titleMrField')), 'T');
        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'L');
        await tester.enterText(find.byKey(const Key('slotLabelMr_0')), 'L');
        await tester.enterText(find.byKey(const Key('slotCapacity_0')), '1');
        await pickSlotDate(tester);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(
          find.text('Failed to create sign up. Please try again.'),
          findsOneWidget,
        );
        final signups = await firestore.collection('signups').get();
        expect(signups.docs, isEmpty);
      },
    );

    testWidgets(
      'submits and creates the signup and slot together, without a join code',
      (tester) async {
        await pumpScreen(tester);

        await tester.enterText(
          find.byKey(const Key('titleEnField')),
          'Sunday Prasad Seva',
        );
        await tester.enterText(
          find.byKey(const Key('titleMrField')),
          'रविवार प्रसाद सेवा',
        );

        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('slotLabelEn_0')),
          'Week 1',
        );
        await tester.enterText(
          find.byKey(const Key('slotLabelMr_0')),
          'आठवडा १',
        );
        await tester.enterText(find.byKey(const Key('slotCapacity_0')), '3');
        await pickSlotDate(tester);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final signups = await firestore.collection('signups').get();
        expect(signups.docs.length, 1);
        final signupData = signups.docs.first.data();
        expect(signupData['titleEn'], 'Sunday Prasad Seva');
        expect(signupData['titleMr'], 'रविवार प्रसाद सेवा');
        expect(signupData['groupId'], 'gajanan_maharaj_seattle');
        expect(signupData['status'], 'draft');
        expect(signupData['requiresJoinCode'], false);
        expect(signupData['joinCode'], isNull);

        final slots = await firestore
            .collection('signups')
            .doc(signups.docs.first.id)
            .collection('slots')
            .get();
        expect(slots.docs.length, 1);
        expect(slots.docs.first.data()['labelEn'], 'Week 1');
        expect(slots.docs.first.data()['labelMr'], 'आठवडा १');
        expect(slots.docs.first.data()['capacity'], 3);
        expect(slots.docs.first.data()['sortOrder'], 0);
      },
    );

    testWidgets('stores the picked date as a whole-day range in Pacific time', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'L');
      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '2');
      await pickSlotDate(tester); // the picker opens on today
      final today = DateTime.now();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final signup = (await firestore.collection('signups').get()).docs.single;
      final slot = (await signup.reference.collection('slots').get())
          .docs
          .single
          .data();
      expect(slot.containsKey('date'), isFalse);
      expect(slot['timezone'], EventTimezone.pacific);
      expect(
        (slot['startAt'] as Timestamp).toDate().toUtc(),
        wallClockToUtc(
          year: today.year,
          month: today.month,
          day: today.day,
          timezone: EventTimezone.pacific,
        ),
      );
      expect(
        (slot['endAt'] as Timestamp).toDate().toUtc(),
        wallClockToUtc(
          year: today.year,
          month: today.month,
          day: today.day,
          hour: 23,
          minute: 59,
          timezone: EventTimezone.pacific,
        ),
      );
    });

    group('slot schedule', () {
      testWidgets('start and end times are saved in the slot\'s zone', (
        tester,
      ) async {
        await pumpScreen(tester);
        await fillFirstSlot(tester);
        await pickSlotDate(tester);
        await acceptTime(tester, const Key('slotStartTime_0')); // 9:00 AM
        await acceptTime(tester, const Key('slotEndTime_0')); // 10:00 AM
        final today = DateTime.now();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final slot = await onlySlot();
        DateTime at(int hour) => wallClockToUtc(
          year: today.year,
          month: today.month,
          day: today.day,
          hour: hour,
          timezone: EventTimezone.pacific,
        );
        expect(instantOf(slot, 'startAt'), at(9));
        expect(instantOf(slot, 'endAt'), at(10));
        expect(slot['timezone'], EventTimezone.pacific);
      });

      testWidgets('an end date on a later day makes a multi-day slot', (
        tester,
      ) async {
        await pumpScreen(tester);
        await fillFirstSlot(tester);
        await pickSlotDate(tester);
        final today = DateTime.now();
        final later = today.add(const Duration(days: 3));
        await pickDate(
          tester,
          const Key('slotEndDate_0'),
          openedOn: today,
          target: later,
        );

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final slot = await onlySlot();
        // Midnight on the first day to 23:59 on the last, in Pacific time.
        expect(
          instantOf(slot, 'startAt'),
          wallClockToUtc(
            year: today.year,
            month: today.month,
            day: today.day,
            timezone: EventTimezone.pacific,
          ),
        );
        expect(
          instantOf(slot, 'endAt'),
          wallClockToUtc(
            year: later.year,
            month: later.month,
            day: later.day,
            hour: 23,
            minute: 59,
            timezone: EventTimezone.pacific,
          ),
        );
      });

      testWidgets('a start moved past the end blocks saving and creates '
          'nothing', (tester) async {
        await pumpScreen(tester);
        await fillFirstSlot(tester);
        await pickSlotDate(tester);
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        await pickDate(
          tester,
          const Key('slotEndDate_0'),
          openedOn: today,
          target: tomorrow,
        );
        // Move the start two days past the end.
        await pickDate(
          tester,
          const Key('slotStartDate_0'),
          openedOn: today,
          target: today.add(const Duration(days: 3)),
        );

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('End must be after the start'), findsOneWidget);
        expect((await firestore.collection('signups').get()).docs, isEmpty);
      });

      testWidgets('a first slot starts on Pacific time when the group has no '
          'setting', (tester) async {
        await pumpScreen(tester);
        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const Key('slotTimezone_0')),
            matching: find.text('Seattle (Pacific Time)'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('a Gunjan admin\'s first slot starts on India time and '
          'is saved that way', (tester) async {
        when(() => appConfigProvider.appConfig).thenReturn(
          AppConfig(
            deities: const [],
            gajananMaharajGroups: [
              GajananMaharajGroup(
                id: 'gajanan_gunjan',
                nameEn: 'Gunjan',
                nameMr: 'गुंजन',
                defaultTimezone: EventTimezone.india,
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
        adminUser = const AdminUser(
          email: 'admin@test.com',
          roles: ['group_admin'],
          groupId: 'gajanan_gunjan',
        );
        await pumpScreen(tester);
        await fillFirstSlot(tester);
        await pickSlotDate(tester);
        final today = DateTime.now();

        expect(find.text('India (IST)'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final slot = await onlySlot();
        expect(slot['timezone'], EventTimezone.india);
        expect(
          instantOf(slot, 'startAt'),
          wallClockToUtc(
            year: today.year,
            month: today.month,
            day: today.day,
            timezone: EventTimezone.india,
          ),
        );
      });

      testWidgets('a second slot starts in the zone the first one was changed '
          'to', (tester) async {
        await pumpScreen(tester);
        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('slotTimezone_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('India (IST)').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Add Slot'));
        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const Key('slotTimezone_1')),
            matching: find.text('India (IST)'),
          ),
          findsOneWidget,
        );
      });

      Future<void> addSlotRow(
        WidgetTester tester,
        int index,
        String label, {
        String? timezoneLabel,
      }) async {
        await tester.ensureVisible(find.text('Add Slot'));
        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(Key('slotLabelEn_$index')));
        await tester.enterText(find.byKey(Key('slotLabelEn_$index')), label);
        await tester.enterText(find.byKey(Key('slotCapacity_$index')), '2');
        if (timezoneLabel != null) {
          await tester.ensureVisible(find.byKey(Key('slotTimezone_$index')));
          await tester.tap(find.byKey(Key('slotTimezone_$index')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(timezoneLabel).last);
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.byKey(Key('slotStartDate_$index')));
        await pickSlotDate(tester, index);
      }

      Future<Map<String, Map<String, dynamic>>> savedSlotsByLabel() async {
        final signup =
            (await firestore.collection('signups').get()).docs.single;
        final slots = await signup.reference.collection('slots').get();
        return {for (final d in slots.docs) d.data()['labelEn']: d.data()};
      }

      testWidgets('removing a slot above leaves the others\' schedules '
          'intact when saved', (tester) async {
        await pumpScreen(tester);
        await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
        await addSlotRow(tester, 0, 'A');
        await addSlotRow(tester, 1, 'B', timezoneLabel: 'India (IST)');
        await tester.ensureVisible(find.byKey(const Key('slotStartTime_1')));
        await acceptTime(tester, const Key('slotStartTime_1')); // 9:00 AM
        final today = DateTime.now();

        await tester.ensureVisible(find.byTooltip('Remove slot').first);
        await tester.tap(find.byTooltip('Remove slot').first);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final slots = await savedSlotsByLabel();
        expect(slots.keys, ['B']);
        expect(slots['B']!['timezone'], EventTimezone.india);
        expect(
          instantOf(slots['B']!, 'startAt'),
          wallClockToUtc(
            year: today.year,
            month: today.month,
            day: today.day,
            hour: 9,
            timezone: EventTimezone.india,
          ),
        );
      });

      testWidgets('saving after moving a slot stores the new order with '
          'each slot\'s own schedule', (tester) async {
        await pumpScreen(tester);
        await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
        await addSlotRow(tester, 0, 'A');
        await addSlotRow(tester, 1, 'B', timezoneLabel: 'India (IST)');
        await tester.ensureVisible(find.byTooltip('Move slot down').first);
        await tester.tap(find.byTooltip('Move slot down').first);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final slots = await savedSlotsByLabel();
        expect(slots['B']!['sortOrder'], 0);
        expect(slots['A']!['sortOrder'], 1);
        expect(slots['B']!['timezone'], EventTimezone.india);
        expect(slots['A']!['timezone'], EventTimezone.pacific);
      });

      testWidgets('a failed save keeps the schedule that was entered', (
        tester,
      ) async {
        adminUser = const AdminUser(
          email: 'admin@test.com',
          roles: ['group_admin'],
        ); // no group, so saving fails
        await pumpScreen(tester);
        await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
        await addSlotRow(tester, 0, 'A', timezoneLabel: 'India (IST)');
        await acceptTime(tester, const Key('slotStartTime_0'));

        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(
          find.text('Failed to create sign up. Please try again.'),
          findsOneWidget,
        );
        expect(find.text('India (IST)'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('slotStartTime_0')),
            matching: find.text('9:00 AM'),
          ),
          findsOneWidget,
        );
        expect((await firestore.collection('signups').get()).docs, isEmpty);
      });

      testWidgets('fits a 320 px phone at double text size', (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(() {
          tester.view.reset();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        await tester.pumpWidget(
          createWidget(
            AdminCreateSignupScreen(
              adminUser: adminUser,
              firestore: firestore,
              storage: storage,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Add Slot'));
        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('slotStartDate_0')));
        await pickSlotDate(tester);
        await tester.ensureVisible(find.byKey(const Key('slotStartTime_0')));
        await acceptTime(tester, const Key('slotStartTime_0'));
        await acceptTime(tester, const Key('slotEndTime_0'));

        expect(tester.takeException(), isNull);
      });

      testWidgets('moving a slot keeps its own schedule', (tester) async {
        await pumpScreen(tester);
        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('slotTimezone_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('India (IST)').last);
        await tester.pumpAndSettle();
        await pickSlotDate(tester, 0);
        await tester.ensureVisible(find.text('Add Slot'));
        await tester.tap(find.text('Add Slot')); // inherits India
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('slotTimezone_1')));
        await tester.tap(find.byKey(const Key('slotTimezone_1')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Seattle (Pacific Time)').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byTooltip('Move slot down').first);
        await tester.tap(find.byTooltip('Move slot down').first);
        await tester.pumpAndSettle();

        // The Seattle slot is first now, the India one (with its date) second.
        Finder shown(int row, String text) => find.descendant(
          of: find.byKey(Key('slotTimezone_$row')),
          matching: find.text(text),
        );
        expect(shown(0, 'Seattle (Pacific Time)'), findsOneWidget);
        expect(shown(1, 'India (IST)'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('slotStartDate_1')),
            matching: find.text('Select Date'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('slotStartDate_0')),
            matching: find.text('Select Date'),
          ),
          findsOneWidget,
        );
      });
    });

    testWidgets('generates a join code only when the toggle is enabled', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
      await tester.enterText(find.byKey(const Key('titleMrField')), 'T');
      await tester.tap(find.text('Require a join code to sign up'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'L');
      await tester.enterText(find.byKey(const Key('slotLabelMr_0')), 'L');
      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '1');
      await pickSlotDate(tester);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final signups = await firestore.collection('signups').get();
      final data = signups.docs.first.data();
      expect(data['requiresJoinCode'], true);
      expect(data['joinCode'], isNotNull);
      expect((data['joinCode'] as String).length, 6);
    });

    group('header image', () {
      testWidgets('shows Add Image when none is picked', (tester) async {
        await pumpScreen(tester);

        expect(find.byKey(const Key('addHeaderImageButton')), findsOneWidget);
        expect(find.byKey(const Key('removeHeaderImageButton')), findsNothing);
      });

      testWidgets('picking an image shows a preview with a remove control', (
        tester,
      ) async {
        ImagePickerPlatform.instance = FakeImagePickerPlatform(
          imageBytes: _validPngBytes,
        );
        await pumpScreen(tester);

        await tester.tap(find.byKey(const Key('addHeaderImageButton')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('addHeaderImageButton')), findsNothing);
        expect(
          find.byKey(const Key('removeHeaderImageButton')),
          findsOneWidget,
        );
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('removing a picked image returns to the Add Image state', (
        tester,
      ) async {
        ImagePickerPlatform.instance = FakeImagePickerPlatform(
          imageBytes: _validPngBytes,
        );
        await pumpScreen(tester);
        await tester.tap(find.byKey(const Key('addHeaderImageButton')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('removeHeaderImageButton')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('addHeaderImageButton')), findsOneWidget);
        expect(find.byKey(const Key('removeHeaderImageButton')), findsNothing);
      });

      testWidgets(
        'shows an error and keeps Add Image when the picked file is too large',
        (tester) async {
          ImagePickerPlatform.instance = FakeImagePickerPlatform(
            imageBytes: Uint8List(3 * 1024 * 1024),
          );
          await pumpScreen(tester);

          await tester.tap(find.byKey(const Key('addHeaderImageButton')));
          await tester.pumpAndSettle();

          expect(find.text('Image must be smaller than 2 MB'), findsOneWidget);
          expect(find.byKey(const Key('addHeaderImageButton')), findsOneWidget);
        },
      );

      testWidgets(
        'submits with the picked image uploaded and headerImageUrl set',
        (tester) async {
          ImagePickerPlatform.instance = FakeImagePickerPlatform(
            imageBytes: _validPngBytes,
          );
          await pumpScreen(tester);
          await tester.tap(find.byKey(const Key('addHeaderImageButton')));
          await tester.pumpAndSettle();

          await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
          await tester.enterText(find.byKey(const Key('titleMrField')), 'T');
          await tester.tap(find.text('Add Slot'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'L');
          await tester.enterText(find.byKey(const Key('slotLabelMr_0')), 'L');
          await tester.enterText(find.byKey(const Key('slotCapacity_0')), '1');
          await pickSlotDate(tester);

          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();

          final signups = await firestore.collection('signups').get();
          final data = signups.docs.first.data();
          expect(data['headerImageUrl'], isNotNull);
          expect(
            storage.storedDataMap.containsKey(
              'signups/${signups.docs.first.id}/header',
            ),
            true,
          );
        },
      );

      testWidgets('submits with no headerImageUrl when no image was picked', (
        tester,
      ) async {
        await pumpScreen(tester);

        await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
        await tester.enterText(find.byKey(const Key('titleMrField')), 'T');
        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'L');
        await tester.enterText(find.byKey(const Key('slotLabelMr_0')), 'L');
        await tester.enterText(find.byKey(const Key('slotCapacity_0')), '1');
        await pickSlotDate(tester);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final signups = await firestore.collection('signups').get();
        expect(signups.docs.first.data()['headerImageUrl'], isNull);
      });

      testWidgets(
        'cleans up the uploaded image if signup creation fails afterward',
        (tester) async {
          ImagePickerPlatform.instance = FakeImagePickerPlatform(
            imageBytes: _validPngBytes,
          );
          final mockService = MockSignupService();
          when(() => mockService.newSignupId()).thenReturn('signup_orphan');
          when(
            () => mockService.uploadHeaderImage(
              signupId: any(named: 'signupId'),
              bytes: any(named: 'bytes'),
              contentType: any(named: 'contentType'),
            ),
          ).thenAnswer((_) async => 'https://example.com/header.jpg');
          when(
            () => mockService.createSignupWithSlots(any(), any()),
          ).thenThrow(Exception('Firestore write failed'));
          when(
            () => mockService.deleteHeaderImageFile('signup_orphan'),
          ).thenAnswer((_) async {});

          setLargeScreen(tester);
          addTearDown(() => resetScreen(tester));
          await tester.pumpWidget(
            createWidget(
              AdminCreateSignupScreen(
                adminUser: adminUser,
                signupService: mockService,
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('addHeaderImageButton')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
          await tester.enterText(find.byKey(const Key('titleMrField')), 'T');
          await tester.tap(find.text('Add Slot'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'L');
          await tester.enterText(find.byKey(const Key('slotLabelMr_0')), 'L');
          await tester.enterText(find.byKey(const Key('slotCapacity_0')), '1');
          await pickSlotDate(tester);

          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();

          verify(
            () => mockService.deleteHeaderImageFile('signup_orphan'),
          ).called(1);
          expect(
            find.text('Failed to create sign up. Please try again.'),
            findsOneWidget,
          );
        },
      );

      testWidgets('still shows the original error when cleanup itself fails', (
        tester,
      ) async {
        ImagePickerPlatform.instance = FakeImagePickerPlatform(
          imageBytes: _validPngBytes,
        );
        final mockService = MockSignupService();
        when(() => mockService.newSignupId()).thenReturn('signup_orphan2');
        when(
          () => mockService.uploadHeaderImage(
            signupId: any(named: 'signupId'),
            bytes: any(named: 'bytes'),
            contentType: any(named: 'contentType'),
          ),
        ).thenAnswer((_) async => 'https://example.com/header.jpg');
        when(
          () => mockService.createSignupWithSlots(any(), any()),
        ).thenThrow(Exception('Firestore write failed'));
        when(
          () => mockService.deleteHeaderImageFile('signup_orphan2'),
        ).thenThrow(Exception('cleanup also failed'));

        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));
        await tester.pumpWidget(
          createWidget(
            AdminCreateSignupScreen(
              adminUser: adminUser,
              signupService: mockService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('addHeaderImageButton')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('titleEnField')), 'T');
        await tester.enterText(find.byKey(const Key('titleMrField')), 'T');
        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'L');
        await tester.enterText(find.byKey(const Key('slotLabelMr_0')), 'L');
        await tester.enterText(find.byKey(const Key('slotCapacity_0')), '1');
        await pickSlotDate(tester);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // The cleanup's own failure must not surface or replace the
        // original "failed to create signup" message.
        expect(
          find.text('Failed to create sign up. Please try again.'),
          findsOneWidget,
        );
      });
    });
  });
}

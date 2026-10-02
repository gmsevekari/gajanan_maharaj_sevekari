import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_create_signup_sheet_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
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
      SignupSheet(
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
        AdminCreateSignupSheetScreen(
          adminUser: adminUser,
          firestore: firestore,
          storage: storage,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AdminCreateSignupSheetScreen', () {
    testWidgets(
      'renders title/description fields, join code toggle, and empty slot state',
      (tester) async {
        await pumpScreen(tester);

        expect(find.text('Title (English)'), findsOneWidget);
        expect(find.text('Title (Marathi)'), findsOneWidget);
        expect(find.text('Description (English)'), findsOneWidget);
        expect(find.text('Description (Marathi)'), findsOneWidget);
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
      expect(find.text('Please enter Marathi title'), findsOneWidget);
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
      expect(find.text('Slot Label (Marathi)'), findsOneWidget);
      expect(find.text('Capacity'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an English label'), findsOneWidget);
      expect(find.text('Please enter a Marathi label'), findsOneWidget);
      expect(find.text('Please enter a capacity'), findsOneWidget);
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
      await tester.enterText(
        find.byKey(const Key('slotSuggestedAmount_0')),
        '50.5',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid amount'), findsNothing);
      final sheets = await firestore.collection('signups').get();
      final slots = await firestore
          .collection('signups')
          .doc(sheets.docs.first.id)
          .collection('slots')
          .get();
      expect(slots.docs.first.data()['suggestedAmount'], 50.5);
    });

    testWidgets('picking a date shows it on the row, and it can be cleared', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();

      expect(find.text('No date set'), findsOneWidget);

      await tester.tap(find.text('Set Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('No date set'), findsNothing);
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('No date set'), findsOneWidget);
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

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(
          find.text('Failed to create sign up. Please try again.'),
          findsOneWidget,
        );
        final sheets = await firestore.collection('signups').get();
        expect(sheets.docs, isEmpty);
      },
    );

    testWidgets(
      'submits and creates the sheet and slot together, without a join code',
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

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final sheets = await firestore.collection('signups').get();
        expect(sheets.docs.length, 1);
        final sheetData = sheets.docs.first.data();
        expect(sheetData['titleEn'], 'Sunday Prasad Seva');
        expect(sheetData['titleMr'], 'रविवार प्रसाद सेवा');
        expect(sheetData['groupId'], 'gajanan_maharaj_seattle');
        expect(sheetData['status'], 'draft');
        expect(sheetData['requiresJoinCode'], false);
        expect(sheetData['joinCode'], isNull);

        final slots = await firestore
            .collection('signups')
            .doc(sheets.docs.first.id)
            .collection('slots')
            .get();
        expect(slots.docs.length, 1);
        expect(slots.docs.first.data()['labelEn'], 'Week 1');
        expect(slots.docs.first.data()['labelMr'], 'आठवडा १');
        expect(slots.docs.first.data()['capacity'], 3);
        expect(slots.docs.first.data()['sortOrder'], 0);
      },
    );

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

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final sheets = await firestore.collection('signups').get();
      final data = sheets.docs.first.data();
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

          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();

          final sheets = await firestore.collection('signups').get();
          final data = sheets.docs.first.data();
          expect(data['headerImageUrl'], isNotNull);
          expect(
            storage.storedDataMap.containsKey(
              'signups/${sheets.docs.first.id}/header',
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

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final sheets = await firestore.collection('signups').get();
        expect(sheets.docs.first.data()['headerImageUrl'], isNull);
      });

      testWidgets(
        'cleans up the uploaded image if sheet creation fails afterward',
        (tester) async {
          ImagePickerPlatform.instance = FakeImagePickerPlatform(
            imageBytes: _validPngBytes,
          );
          final mockService = MockSignupService();
          when(() => mockService.newSheetId()).thenReturn('sheet_orphan');
          when(
            () => mockService.uploadHeaderImage(
              sheetId: any(named: 'sheetId'),
              bytes: any(named: 'bytes'),
              contentType: any(named: 'contentType'),
            ),
          ).thenAnswer((_) async => 'https://example.com/header.jpg');
          when(
            () => mockService.createSheetWithSlots(any(), any()),
          ).thenThrow(Exception('Firestore write failed'));
          when(
            () => mockService.deleteHeaderImageFile('sheet_orphan'),
          ).thenAnswer((_) async {});

          setLargeScreen(tester);
          addTearDown(() => resetScreen(tester));
          await tester.pumpWidget(
            createWidget(
              AdminCreateSignupSheetScreen(
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

          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();

          verify(
            () => mockService.deleteHeaderImageFile('sheet_orphan'),
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
        when(() => mockService.newSheetId()).thenReturn('sheet_orphan2');
        when(
          () => mockService.uploadHeaderImage(
            sheetId: any(named: 'sheetId'),
            bytes: any(named: 'bytes'),
            contentType: any(named: 'contentType'),
          ),
        ).thenAnswer((_) async => 'https://example.com/header.jpg');
        when(
          () => mockService.createSheetWithSlots(any(), any()),
        ).thenThrow(Exception('Firestore write failed'));
        when(
          () => mockService.deleteHeaderImageFile('sheet_orphan2'),
        ).thenThrow(Exception('cleanup also failed'));

        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));
        await tester.pumpWidget(
          createWidget(
            AdminCreateSignupSheetScreen(
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

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // The cleanup's own failure must not surface or replace the
        // original "failed to create sheet" message.
        expect(
          find.text('Failed to create sign up. Please try again.'),
          findsOneWidget,
        );
      });
    });
  });
}

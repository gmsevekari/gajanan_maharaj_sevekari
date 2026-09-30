import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_create_signup_sheet_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminUser adminUser;
  late MockAppConfigProvider appConfigProvider;

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

        final sheets = await firestore.collection('signup_sheets').get();
        expect(sheets.docs.length, 1);
        final sheetData = sheets.docs.first.data();
        expect(sheetData['titleEn'], 'Sunday Prasad Seva');
        expect(sheetData['titleMr'], 'रविवार प्रसाद सेवा');
        expect(sheetData['groupId'], 'gajanan_maharaj_seattle');
        expect(sheetData['status'], 'draft');
        expect(sheetData['requiresJoinCode'], false);
        expect(sheetData['joinCode'], isNull);

        final slots = await firestore
            .collection('signup_sheets')
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

      final sheets = await firestore.collection('signup_sheets').get();
      final data = sheets.docs.first.data();
      expect(data['requiresJoinCode'], true);
      expect(data['joinCode'], isNotNull);
      expect((data['joinCode'] as String).length, 6);
    });
  });
}

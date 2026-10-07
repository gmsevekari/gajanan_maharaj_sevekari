import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_edit_signup_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignupService extends Mock implements SignupService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;
  bool? result;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
    result = null;
  });

  /// A saved sign-up, read back as the edit screen would receive it.
  Future<Signup> seed({
    bool requiresJoinCode = false,
    String? joinCode,
    String titleMr = 'सेवा',
  }) async {
    final now = DateTime.utc(2026, 1, 2);
    final id = await service.createSignup(
      Signup(
        titleEn: 'Sunday Seva',
        titleMr: titleMr,
        descriptionEn: 'Cook and serve',
        descriptionMr: 'शिजवा',
        groupId: 'group_9',
        status: SignupStatus.published,
        requiresJoinCode: requiresJoinCode,
        joinCode: joinCode,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      ),
    );
    await firestore.doc('signups/$id').update({
      'headerImageUrl': 'https://example.com/h.png',
    });
    // Read with get(): a snapshots() stream left open by the fake Firestore
    // keeps pumpWidget from ever returning.
    final snapshot = await firestore.doc('signups/$id').get();
    return Signup.fromMap(id, snapshot.data()!);
  }

  Widget wrap(Widget screen, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => screen),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(
    WidgetTester tester,
    Signup signup, {
    SignupService? withService,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      wrap(
        AdminEditSignupScreen(
          signup: signup,
          signupService: withService ?? service,
        ),
        locale: locale,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  Future<Map<String, dynamic>> stored(Signup signup) async =>
      (await firestore.doc('signups/${signup.id}').get()).data()!;

  String textOf(WidgetTester tester, String key) =>
      tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;

  bool switchValue(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value;

  Future<void> toggleJoinCode(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
  }

  group('showing the sign-up', () {
    testWidgets('has a title and the fields filled in', (tester) async {
      final signup = await seed();
      await open(tester, signup);

      expect(find.text('Edit Sign Up'), findsOneWidget);
      expect(textOf(tester, 'titleEnField'), 'Sunday Seva');
      expect(textOf(tester, 'titleMrField'), 'सेवा');
      expect(textOf(tester, 'descEnField'), 'Cook and serve');
      expect(textOf(tester, 'descMrField'), 'शिजवा');
      expect(find.text('Require a join code to sign up'), findsOneWidget);
    });

    testWidgets('shows the join code switch off when it is not required', (
      tester,
    ) async {
      await open(tester, await seed());

      expect(switchValue(tester), isFalse);
    });

    testWidgets('shows the join code switch on when it is required', (
      tester,
    ) async {
      await open(
        tester,
        await seed(requiresJoinCode: true, joinCode: 'ABC123'),
      );

      expect(switchValue(tester), isTrue);
    });

    testWidgets('does not offer the status, group or image here', (
      tester,
    ) async {
      await open(tester, await seed());

      expect(find.byKey(const Key('addHeaderImageButton')), findsNothing);
      expect(find.text('Published'), findsNothing);
    });
  });

  group('saving', () {
    testWidgets('writes the changes, trims them, and closes with true', (
      tester,
    ) async {
      final signup = await seed();
      await open(tester, signup);

      await tester.enterText(
        find.byKey(const Key('titleEnField')),
        '  Monday Seva ',
      );
      await tester.enterText(find.byKey(const Key('titleMrField')), 'सोमवार');
      await tester.enterText(
        find.byKey(const Key('descEnField')),
        ' New text ',
      );
      await tester.enterText(find.byKey(const Key('descMrField')), 'नवे');
      await save(tester);

      final data = await stored(signup);
      expect(data['titleEn'], 'Monday Seva');
      expect(data['titleMr'], 'सोमवार');
      expect(data['descriptionEn'], 'New text');
      expect(data['descriptionMr'], 'नवे');
      expect(result, isTrue);
      expect(find.text('Edit Sign Up'), findsNothing);
    });

    testWidgets('leaves the status, group, image and creator alone', (
      tester,
    ) async {
      final signup = await seed();
      await open(tester, signup);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'Changed');
      await save(tester);

      final data = await stored(signup);
      expect(data['status'], 'published');
      expect(data['groupId'], 'group_9');
      expect(data['headerImageUrl'], 'https://example.com/h.png');
      expect(data['createdBy'], 'admin@test.com');
    });

    testWidgets('lets the Marathi title and both descriptions be cleared', (
      tester,
    ) async {
      final signup = await seed();
      await open(tester, signup);

      await tester.enterText(find.byKey(const Key('titleMrField')), '');
      await tester.enterText(find.byKey(const Key('descEnField')), '');
      await tester.enterText(find.byKey(const Key('descMrField')), '');
      await save(tester);

      final data = await stored(signup);
      expect(data['titleMr'], '');
      expect(data['descriptionEn'], '');
      expect(data['descriptionMr'], '');
      expect(result, isTrue);
    });

    testWidgets('needs an English title, and writes nothing without one', (
      tester,
    ) async {
      final signup = await seed();
      await open(tester, signup);

      await tester.enterText(find.byKey(const Key('titleEnField')), '   ');
      await save(tester);

      expect(find.text('Please enter English title'), findsOneWidget);
      expect((await stored(signup))['titleEn'], 'Sunday Seva');
      expect(result, isNull);
      expect(find.text('Edit Sign Up'), findsOneWidget);
    });

    testWidgets('closes without writing when nothing changed', (tester) async {
      final signup = await seed();
      final spy = _MockSignupService();
      when(
        () => spy.updateSignupDetails(
          any(),
          titleEn: any(named: 'titleEn'),
          titleMr: any(named: 'titleMr'),
          descriptionEn: any(named: 'descriptionEn'),
          descriptionMr: any(named: 'descriptionMr'),
          requiresJoinCode: any(named: 'requiresJoinCode'),
          joinCode: any(named: 'joinCode'),
        ),
      ).thenAnswer((_) async {});
      await open(tester, signup, withService: spy);

      await save(tester);

      verifyNever(
        () => spy.updateSignupDetails(
          any(),
          titleEn: any(named: 'titleEn'),
          titleMr: any(named: 'titleMr'),
          descriptionEn: any(named: 'descriptionEn'),
          descriptionMr: any(named: 'descriptionMr'),
          requiresJoinCode: any(named: 'requiresJoinCode'),
          joinCode: any(named: 'joinCode'),
        ),
      );
      expect(find.text('Edit Sign Up'), findsNothing);
      expect(result, isNot(true));
    });
  });

  group('the join code', () {
    testWidgets('keeps the same code when other things are edited', (
      tester,
    ) async {
      final signup = await seed(requiresJoinCode: true, joinCode: 'ABC123');
      await open(tester, signup);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'Changed');
      await save(tester);

      expect((await stored(signup))['joinCode'], 'ABC123');
      expect(find.text('Turn on the join code?'), findsNothing);
      expect(find.text('Turn off the join code?'), findsNothing);
    });

    testWidgets('asks before turning it on, and makes a new code when saved', (
      tester,
    ) async {
      final signup = await seed();
      await open(tester, signup);

      await toggleJoinCode(tester);
      expect(switchValue(tester), isTrue);
      expect(find.text('Turn on the join code?'), findsNothing);
      await save(tester);

      expect(find.text('Turn on the join code?'), findsOneWidget);
      expect(
        find.textContaining("Links and messages you shared earlier don't "),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      final data = await stored(signup);
      expect(data['requiresJoinCode'], true);
      expect(data['joinCode'], matches(RegExp(r'^[A-Z0-9]{6}$')));
      expect(result, isTrue);
    });

    testWidgets('writes nothing when turning it on is not confirmed', (
      tester,
    ) async {
      final signup = await seed();
      await open(tester, signup);

      await toggleJoinCode(tester);
      await save(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect((await stored(signup))['requiresJoinCode'], false);
      expect(result, isNull);
      expect(find.text('Edit Sign Up'), findsOneWidget);
      // The form is as it was left.
      expect(switchValue(tester), isTrue);
    });

    testWidgets('asks before turning it off, and removes the code', (
      tester,
    ) async {
      final signup = await seed(requiresJoinCode: true, joinCode: 'ABC123');
      await open(tester, signup);

      await toggleJoinCode(tester);
      expect(switchValue(tester), isFalse);
      await save(tester);

      expect(find.text('Turn off the join code?'), findsOneWidget);
      expect(
        find.textContaining('Anyone with the link will be able to sign up'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      final data = await stored(signup);
      expect(data['requiresJoinCode'], false);
      expect(data['joinCode'], isNull);
      expect(result, isTrue);
    });

    testWidgets('keeps the code when turning it off is not confirmed', (
      tester,
    ) async {
      final signup = await seed(requiresJoinCode: true, joinCode: 'ABC123');
      await open(tester, signup);

      await toggleJoinCode(tester);
      await save(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      final data = await stored(signup);
      expect(data['requiresJoinCode'], true);
      expect(data['joinCode'], 'ABC123');
    });

    testWidgets('does not ask when the switch is put back as it was', (
      tester,
    ) async {
      final signup = await seed(requiresJoinCode: true, joinCode: 'ABC123');
      await open(tester, signup);

      await toggleJoinCode(tester);
      await toggleJoinCode(tester);
      await tester.enterText(find.byKey(const Key('titleEnField')), 'Changed');
      await save(tester);

      expect(find.text('Turn off the join code?'), findsNothing);
      expect((await stored(signup))['joinCode'], 'ABC123');
    });

    testWidgets('changes the switch together with the text in one save', (
      tester,
    ) async {
      final signup = await seed();
      await open(tester, signup);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'Both');
      await toggleJoinCode(tester);
      await save(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      final data = await stored(signup);
      expect(data['titleEn'], 'Both');
      expect(data['requiresJoinCode'], true);
      expect(data['joinCode'], isNotNull);
    });

    testWidgets('does not ask about the join code when the title is invalid', (
      tester,
    ) async {
      final signup = await seed();
      await open(tester, signup);

      await tester.enterText(find.byKey(const Key('titleEnField')), '');
      await toggleJoinCode(tester);
      await save(tester);

      expect(find.text('Please enter English title'), findsOneWidget);
      expect(find.text('Turn on the join code?'), findsNothing);
    });
  });

  group('when saving goes wrong', () {
    _MockSignupService failing(Object error) {
      final mock = _MockSignupService();
      when(
        () => mock.updateSignupDetails(
          any(),
          titleEn: any(named: 'titleEn'),
          titleMr: any(named: 'titleMr'),
          descriptionEn: any(named: 'descriptionEn'),
          descriptionMr: any(named: 'descriptionMr'),
          requiresJoinCode: any(named: 'requiresJoinCode'),
          joinCode: any(named: 'joinCode'),
        ),
      ).thenThrow(error);
      return mock;
    }

    testWidgets('says so plainly and keeps what was typed', (tester) async {
      final signup = await seed();
      await open(
        tester,
        signup,
        withService: failing(Exception('permission-denied: secret')),
      );

      await tester.enterText(find.byKey(const Key('titleEnField')), 'Typed');
      await save(tester);

      expect(find.text('Failed to update sign up'), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      expect(textOf(tester, 'titleEnField'), 'Typed');
      expect(find.text('Edit Sign Up'), findsOneWidget);
      expect(result, isNull);
    });

    testWidgets('clears the message once something is edited', (tester) async {
      final signup = await seed();
      await open(tester, signup, withService: failing(Exception('down')));
      await tester.enterText(find.byKey(const Key('titleEnField')), 'Typed');
      await save(tester);
      expect(find.text('Failed to update sign up'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'Typed 2');
      await tester.pump();

      expect(find.text('Failed to update sign up'), findsNothing);
    });

    testWidgets('allows trying again', (tester) async {
      final signup = await seed();
      final flaky = _MockSignupService();
      var calls = 0;
      when(
        () => flaky.updateSignupDetails(
          any(),
          titleEn: any(named: 'titleEn'),
          titleMr: any(named: 'titleMr'),
          descriptionEn: any(named: 'descriptionEn'),
          descriptionMr: any(named: 'descriptionMr'),
          requiresJoinCode: any(named: 'requiresJoinCode'),
          joinCode: any(named: 'joinCode'),
        ),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('network');
      });
      await open(tester, signup, withService: flaky);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'Typed');
      await save(tester);
      await save(tester);

      expect(calls, 2);
      expect(result, isTrue);
    });

    testWidgets('disables Save while saving', (tester) async {
      final signup = await seed();
      final done = Completer<void>();
      final slow = _MockSignupService();
      when(
        () => slow.updateSignupDetails(
          any(),
          titleEn: any(named: 'titleEn'),
          titleMr: any(named: 'titleMr'),
          descriptionEn: any(named: 'descriptionEn'),
          descriptionMr: any(named: 'descriptionMr'),
          requiresJoinCode: any(named: 'requiresJoinCode'),
          joinCode: any(named: 'joinCode'),
        ),
      ).thenAnswer((_) => done.future);
      await open(tester, signup, withService: slow);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'Typed');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(find.byType(ElevatedButton).last)
            .onPressed,
        isNull,
      );

      done.complete();
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('re-enables Save when the failure is a programming error', (
      tester,
    ) async {
      final signup = await seed();
      await open(tester, signup, withService: failing(ArgumentError('x')));

      await tester.enterText(find.byKey(const Key('titleEnField')), 'Typed');
      await tester.ensureVisible(find.text('Save'));
      final surfaced = <Object>[];
      await runZonedGuarded(() async {
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
      }, (error, _) => surfaced.add(error));

      expect(surfaced.single, isA<ArgumentError>());
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(find.byType(ElevatedButton).last)
            .onPressed,
        isNotNull,
      );
    });
  });

  group('leaving without saving', () {
    testWidgets('goes straight back when nothing changed', (tester) async {
      await open(tester, await seed());

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Edit Sign Up'), findsNothing);
      expect(find.text('Discard changes?'), findsNothing);
    });

    for (final (key, value) in [
      ('titleEnField', 'Other'),
      ('titleMrField', 'इतर'),
      ('descEnField', 'Other text'),
      ('descMrField', 'इतर वर्णन'),
    ]) {
      testWidgets('asks first when $key changed', (tester) async {
        await open(tester, await seed());

        await tester.enterText(find.byKey(Key(key)), value);
        await tester.pump();
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.text('Discard changes?'), findsOneWidget);
      });
    }

    testWidgets('asks first when only the join code switch changed', (
      tester,
    ) async {
      await open(tester, await seed());

      await toggleJoinCode(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('leaves, saving nothing, on Discard', (tester) async {
      final signup = await seed();
      await open(tester, signup);

      await tester.enterText(find.byKey(const Key('titleEnField')), 'Other');
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Sign Up'), findsNothing);
      expect(result, isNull);
      expect((await stored(signup))['titleEn'], 'Sunday Seva');
    });

    testWidgets('does not ask after a successful save', (tester) async {
      await open(tester, await seed());

      await tester.enterText(find.byKey(const Key('titleEnField')), 'Other');
      await save(tester);

      expect(find.text('Discard changes?'), findsNothing);
      expect(result, isTrue);
    });
  });

  group('screen', () {
    testWidgets('stays in English under a Marathi locale', (tester) async {
      await open(tester, await seed(), locale: const Locale('mr'));

      expect(find.text('Edit Sign Up'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('fits a 360px screen at large text', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await open(tester, await seed());

      expect(tester.takeException(), isNull);
    });
  });
}

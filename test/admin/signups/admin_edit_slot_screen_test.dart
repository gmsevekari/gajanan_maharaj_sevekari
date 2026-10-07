import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_edit_slot_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/slot_fixtures.dart';

class _MockSignupService extends Mock implements SignupService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;
  late String signupId;
  bool? result;

  setUpAll(() {
    registerFallbackValue(scheduledSlot());
  });

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
    result = null;
    final now = DateTime.now();
    signupId = await service.createSignup(
      Signup(
        titleEn: 'Seva',
        titleMr: 'सेवा',
        groupId: 'group_1',
        status: SignupStatus.published,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      ),
    );
  });

  /// Saves [slot] with [claimed] people signed up and returns it as read back.
  Future<SignupSlot> seed(SignupSlot slot, {int claimed = 0}) async {
    final id = await service.addSlot(signupId, slot);
    for (var i = 0; i < claimed; i++) {
      await service.claimSlot(
        signupId: signupId,
        slotId: id,
        name: 'Devotee $i',
      );
    }
    return (await service.getSlots(signupId).first).single;
  }

  SignupSlot timed({
    String labelEn = 'Morning Seva',
    String labelMr = 'सकाळची सेवा',
    int capacity = 5,
    double? amount,
    String timezone = EventTimezone.pacific,
  }) => SignupSlot(
    labelEn: labelEn,
    labelMr: labelMr,
    startAt: wallClock(2030, 7, 3, 18, 0, timezone),
    endAt: wallClock(2030, 7, 3, 19, 30, timezone),
    timezone: timezone,
    capacity: capacity,
    suggestedAmount: amount,
    sortOrder: 4,
    createdAt: DateTime.utc(2026, 1, 2),
  );

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
    SignupSlot slot, {
    SignupService? withService,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      wrap(
        AdminEditSlotScreen(
          signupId: signupId,
          slot: slot,
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

  Future<SignupSlot> reload() async =>
      (await service.getSlots(signupId).first).single;

  String textOf(WidgetTester tester, String key) =>
      tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;

  Finder button(String key, String text) =>
      find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

  group('showing the slot', () {
    testWidgets('has a title, the fields filled in, and no slot heading', (
      tester,
    ) async {
      final slot = await seed(timed(amount: 25));
      await open(tester, slot);

      expect(find.text('Edit Slot'), findsOneWidget);
      expect(textOf(tester, 'slotLabelEn_0'), 'Morning Seva');
      expect(textOf(tester, 'slotLabelMr_0'), 'सकाळची सेवा');
      expect(textOf(tester, 'slotCapacity_0'), '5');
      expect(textOf(tester, 'slotSuggestedAmount_0'), '25');
      expect(find.text('Slot 1'), findsNothing);
      expect(find.byTooltip('Remove slot'), findsNothing);
    });

    testWidgets('shows the dates and times as they were entered', (
      tester,
    ) async {
      final slot = await seed(timed());
      await open(tester, slot);

      expect(button('slotStartDate_0', 'Jul 3, 2030'), findsOneWidget);
      expect(button('slotStartTime_0', '6:00 PM'), findsOneWidget);
      expect(button('slotEndTime_0', '7:30 PM'), findsOneWidget);
      expect(find.text('Seattle (Pacific Time)'), findsOneWidget);
    });

    testWidgets('shows an Indian slot in its own zone', (tester) async {
      final slot = await seed(timed(timezone: EventTimezone.india));
      await open(tester, slot);

      expect(button('slotStartTime_0', '6:00 PM'), findsOneWidget);
      expect(find.text('India (IST)'), findsOneWidget);
    });

    testWidgets('leaves an empty amount empty', (tester) async {
      final slot = await seed(timed());
      await open(tester, slot);

      expect(textOf(tester, 'slotSuggestedAmount_0'), '');
    });

    testWidgets('shows whole-number amounts without a trailing .0', (
      tester,
    ) async {
      final slot = await seed(timed(amount: 50));
      await open(tester, slot);
      expect(textOf(tester, 'slotSuggestedAmount_0'), '50');
    });
  });

  group('saving', () {
    testWidgets('writes the changes, keeps everything else, and closes with '
        'true', (tester) async {
      final original = await seed(timed(amount: 25), claimed: 2);
      await open(tester, original);

      await tester.enterText(
        find.byKey(const Key('slotLabelEn_0')),
        '  Evening Seva ',
      );
      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '8');
      await tester.enterText(
        find.byKey(const Key('slotSuggestedAmount_0')),
        '40.5',
      );
      await save(tester);

      final saved = await reload();
      expect(saved.labelEn, 'Evening Seva');
      expect(saved.labelMr, 'सकाळची सेवा');
      expect(saved.capacity, 8);
      expect(saved.suggestedAmount, 40.5);
      // Untouched.
      expect(saved.startAt, original.startAt);
      expect(saved.endAt, original.endAt);
      expect(saved.timezone, original.timezone);
      expect(saved.claimedCount, 2);
      expect(saved.sortOrder, 4);
      expect(saved.createdAt, original.createdAt);
      expect(result, isTrue);
      expect(find.text('Edit Slot'), findsNothing);
    });

    testWidgets('clears the suggested amount when it is emptied', (
      tester,
    ) async {
      final original = await seed(timed(amount: 25));
      await open(tester, original);

      await tester.enterText(
        find.byKey(const Key('slotSuggestedAmount_0')),
        '',
      );
      await save(tester);

      expect((await reload()).suggestedAmount, isNull);
    });

    testWidgets('closes without writing anything when nothing changed', (
      tester,
    ) async {
      final original = await seed(timed(amount: 25));
      final spy = _MockSignupService();
      when(() => spy.updateSlot(any(), any())).thenAnswer((_) async {});
      await open(tester, original, withService: spy);

      await save(tester);

      verifyNever(() => spy.updateSlot(any(), any()));
      expect(find.text('Edit Slot'), findsNothing);
      // Nothing was updated, so the slots page has nothing to confirm.
      expect(result, isNot(true));
      expect(await reload(), original);
    });

    testWidgets('keeps the exact times and timezone of a slot it did not '
        'create when only the label changes', (tester) async {
      // Seconds, and a timezone the app doesn't know: both would be lost by
      // reading them into the form and back.
      final odd = SignupSlot(
        labelEn: 'Imported',
        labelMr: '',
        startAt: DateTime.utc(2030, 7, 3, 16, 0, 30),
        endAt: DateTime.utc(2030, 7, 3, 18, 59, 59),
        timezone: 'Mars/Olympus',
        capacity: 3,
        sortOrder: 0,
        createdAt: DateTime.utc(2026),
      );
      final original = await seed(odd);
      await open(tester, original);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'Renamed');
      await save(tester);

      final saved = await reload();
      expect(saved.labelEn, 'Renamed');
      expect(saved.startAt, original.startAt);
      expect(saved.endAt, original.endAt);
      expect(saved.timezone, 'Mars/Olympus');
    });

    testWidgets('writes the picked schedule once the schedule is changed', (
      tester,
    ) async {
      final odd = SignupSlot(
        labelEn: 'Imported',
        labelMr: '',
        startAt: DateTime.utc(2030, 7, 3, 16, 0, 30),
        endAt: DateTime.utc(2030, 7, 3, 18, 59, 59),
        timezone: 'Mars/Olympus',
        capacity: 3,
        sortOrder: 0,
        createdAt: DateTime.utc(2026),
      );
      final original = await seed(odd);
      await open(tester, original);

      await tester.tap(find.byKey(const Key('slotTimezone_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('India (IST)').last);
      await tester.pumpAndSettle();
      await save(tester);

      final saved = await reload();
      expect(saved.timezone, EventTimezone.india);
      expect(saved.startAt!.second, 0);
    });

    testWidgets('changes the date and keeps the times', (tester) async {
      final original = await seed(timed());
      await open(tester, original);

      await tester.tap(find.byKey(const Key('slotStartDate_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await save(tester);

      final saved = await reload();
      expect(saved.startAt, wallClock(2030, 7, 20, 18));
      expect(saved.endAt, wallClock(2030, 7, 20, 19, 30));
    });

    testWidgets('changes the timezone, keeping the wall-clock times', (
      tester,
    ) async {
      final original = await seed(timed());
      await open(tester, original);

      await tester.tap(find.byKey(const Key('slotTimezone_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('India (IST)').last);
      await tester.pumpAndSettle();
      await save(tester);

      final saved = await reload();
      expect(saved.timezone, EventTimezone.india);
      expect(saved.startAt, wallClock(2030, 7, 3, 18, 0, EventTimezone.india));
    });

    testWidgets('can fill in the schedule of a slot that had none', (
      tester,
    ) async {
      final original = await seed(
        SignupSlot(
          labelEn: 'Undated',
          labelMr: '',
          capacity: 3,
          sortOrder: 0,
          createdAt: DateTime.utc(2026),
        ),
      );
      await open(tester, original);
      await save(tester);
      // The date is mandatory.
      expect(find.text('Please select a date'), findsOneWidget);
      expect((await reload()).startAt, isNull);

      await tester.tap(find.byKey(const Key('slotStartDate_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await save(tester);

      final saved = await reload();
      expect(saved.startAt, isNotNull);
      expect(saved.endAt, isNotNull);
      expect(result, isTrue);
    });
  });

  group('validation', () {
    testWidgets('needs an English label, and writes nothing without it', (
      tester,
    ) async {
      final original = await seed(timed());
      await open(tester, original);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), '  ');
      await save(tester);

      expect(find.text('Please enter an English label'), findsOneWidget);
      expect((await reload()).labelEn, 'Morning Seva');
      expect(result, isNull);
      expect(find.text('Edit Slot'), findsOneWidget);
    });

    testWidgets('does not let the capacity go below the number signed up', (
      tester,
    ) async {
      final original = await seed(timed(), claimed: 3);
      await open(tester, original);

      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '2');
      await save(tester);

      expect(
        find.text("Capacity can't be less than the 3 already signed up"),
        findsOneWidget,
      );
      expect((await reload()).capacity, 5);
    });

    testWidgets('stops a too-small capacity in the form, without trying to '
        'save', (tester) async {
      final mock = _MockSignupService();
      when(() => mock.updateSlot(any(), any())).thenAnswer((_) async {});
      final slot = timed().copyWith(id: 'slot_1', claimedCount: 3);
      await open(tester, slot, withService: mock);

      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '2');
      await save(tester);

      expect(
        find.text("Capacity can't be less than the 3 already signed up"),
        findsOneWidget,
      );
      verifyNever(() => mock.updateSlot(any(), any()));
    });

    testWidgets('lets the capacity equal the number signed up', (tester) async {
      final original = await seed(timed(), claimed: 3);
      await open(tester, original);

      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '3');
      await save(tester);

      expect((await reload()).capacity, 3);
    });

    testWidgets('does not let the end be before the start', (tester) async {
      final original = await seed(timed());
      await open(tester, original);

      // End time 6 AM on the same day, before the 6 PM start.
      await tester.tap(find.byKey(const Key('slotEndTime_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(fields.evaluate().length - 2), '5');
      await tester.enterText(fields.at(fields.evaluate().length - 1), '00');
      await tester.tap(find.text('AM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await save(tester);

      expect(find.text('End must be after the start'), findsOneWidget);
      expect((await reload()).endAt, original.endAt);
    });
  });

  group('when saving goes wrong', () {
    testWidgets('says so, plainly, and keeps the form and what was typed', (
      tester,
    ) async {
      final slot = await seed(timed());
      final failing = _MockSignupService();
      when(
        () => failing.updateSlot(any(), any()),
      ).thenThrow(Exception('permission-denied: secret detail'));
      await open(tester, slot, withService: failing);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'New');
      await save(tester);

      expect(find.text('Failed to update slot'), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      expect(find.text('Edit Slot'), findsOneWidget);
      expect(textOf(tester, 'slotLabelEn_0'), 'New');
      expect(result, isNull);
    });

    testWidgets('names the live count when someone signed up meanwhile', (
      tester,
    ) async {
      final slot = await seed(timed(), claimed: 3);
      await open(tester, slot);
      // Two more sign up while the admin has the form open.
      final id = slot.id!;
      for (final name in ['Ravi', 'Sita']) {
        await service.claimSlot(signupId: signupId, slotId: id, name: name);
      }

      await tester.enterText(find.byKey(const Key('slotCapacity_0')), '4');
      await save(tester);

      expect(
        find.text("Capacity can't be less than the 5 already signed up"),
        findsOneWidget,
      );
      expect((await reload()).capacity, 5);
      expect(find.text('Edit Slot'), findsOneWidget);
    });

    testWidgets('clears the message once the admin edits something', (
      tester,
    ) async {
      final slot = await seed(timed());
      final failing = _MockSignupService();
      when(
        () => failing.updateSlot(any(), any()),
      ).thenThrow(Exception('network'));
      await open(tester, slot, withService: failing);
      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'New');
      await save(tester);
      expect(find.text('Failed to update slot'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'Newer');
      await tester.pump();

      expect(find.text('Failed to update slot'), findsNothing);
    });

    testWidgets('clears the message when the schedule is edited', (
      tester,
    ) async {
      final slot = await seed(timed());
      final failing = _MockSignupService();
      when(
        () => failing.updateSlot(any(), any()),
      ).thenThrow(Exception('network'));
      await open(tester, slot, withService: failing);
      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'New');
      await save(tester);
      expect(find.text('Failed to update slot'), findsOneWidget);

      await tester.tap(find.byKey(const Key('slotTimezone_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('India (IST)').last);
      await tester.pumpAndSettle();

      expect(find.text('Failed to update slot'), findsNothing);
    });

    testWidgets('re-enables Save even when the failure is a programming '
        'error', (tester) async {
      final slot = await seed(timed());
      final broken = _MockSignupService();
      when(() => broken.updateSlot(any(), any())).thenThrow(ArgumentError('x'));
      await open(tester, slot, withService: broken);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'New');
      await tester.ensureVisible(find.text('Save'));
      final surfaced = <Object>[];
      await runZonedGuarded(() async {
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
      }, (error, _) => surfaced.add(error));

      // The error is surfaced rather than hidden, but the screen isn't left
      // spinning.
      expect(surfaced.single, isA<ArgumentError>());
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(find.byType(ElevatedButton).last)
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('allows trying again after a failure', (tester) async {
      final slot = await seed(timed());
      final flaky = _MockSignupService();
      var calls = 0;
      when(() => flaky.updateSlot(any(), any())).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('network');
      });
      await open(tester, slot, withService: flaky);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'New');
      await save(tester);
      expect(find.text('Failed to update slot'), findsOneWidget);
      await save(tester);

      expect(calls, 2);
      expect(result, isTrue);
    });

    testWidgets('disables Save while saving', (tester) async {
      final slot = await seed(timed());
      final done = Completer<void>();
      final slow = _MockSignupService();
      when(() => slow.updateSlot(any(), any())).thenAnswer((_) => done.future);
      await open(tester, slot, withService: slow);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'New');
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
  });

  group('leaving without saving', () {
    testWidgets('goes straight back when nothing changed', (tester) async {
      final slot = await seed(timed());
      await open(tester, slot);

      await tester.pump(); // the form notices the change on the next frame
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Edit Slot'), findsNothing);
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets('asks first when something changed, and can keep editing', (
      tester,
    ) async {
      final slot = await seed(timed());
      await open(tester, slot);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'Other');
      await tester.pump();
      await tester.pump(); // the form notices the change on the next frame
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text("Your changes haven't been saved."), findsOneWidget);

      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Slot'), findsOneWidget);
      expect(textOf(tester, 'slotLabelEn_0'), 'Other');
    });

    testWidgets('leaves, saving nothing, when the changes are discarded', (
      tester,
    ) async {
      final slot = await seed(timed());
      await open(tester, slot);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'Other');
      await tester.pump(); // the form notices the change on the next frame
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Slot'), findsNothing);
      expect(result, isNull);
      expect((await reload()).labelEn, 'Morning Seva');
    });

    testWidgets('asks when only a date or time changed too', (tester) async {
      final slot = await seed(timed());
      await open(tester, slot);

      await tester.tap(find.byKey(const Key('slotTimezone_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('India (IST)').last);
      await tester.pumpAndSettle();
      await tester.pump(); // the form notices the change on the next frame
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
    });

    for (final (field, value) in [
      ('slotLabelMr_0', 'नवीन'),
      ('slotCapacity_0', '9'),
      ('slotSuggestedAmount_0', '15'),
    ]) {
      testWidgets('asks when only $field changed', (tester) async {
        final slot = await seed(timed(amount: 25));
        await open(tester, slot);

        await tester.enterText(find.byKey(Key(field)), value);
        await tester.pump();
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.text('Discard changes?'), findsOneWidget);
      });
    }

    testWidgets('does not open the dialog while a save is in flight', (
      tester,
    ) async {
      final slot = await seed(timed());
      final done = Completer<void>();
      final slow = _MockSignupService();
      when(() => slow.updateSlot(any(), any())).thenAnswer((_) => done.future);
      await open(tester, slot, withService: slow);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'Other');
      await tester.pump();
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pageBack();
      await tester.pump();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Edit Slot'), findsOneWidget);

      done.complete();
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('does not ask again after changing something back', (
      tester,
    ) async {
      final slot = await seed(timed());
      await open(tester, slot);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'Other');
      await tester.enterText(
        find.byKey(const Key('slotLabelEn_0')),
        'Morning Seva',
      );
      await tester.pump(); // the form notices the change on the next frame
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Edit Slot'), findsNothing);
    });

    testWidgets('does not ask after a successful save', (tester) async {
      final slot = await seed(timed());
      await open(tester, slot);

      await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'Other');
      await save(tester);

      expect(find.text('Discard changes?'), findsNothing);
      expect(result, isTrue);
    });
  });

  group('screen', () {
    testWidgets('stays in English under a Marathi locale', (tester) async {
      final slot = await seed(timed());
      await open(tester, slot, locale: const Locale('mr'));

      expect(find.text('Edit Slot'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('fits a 360px screen at large text', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final slot = await seed(
        timed(labelEn: 'A very long slot title that has to wrap on a phone'),
      );

      await open(tester, slot);

      expect(tester.takeException(), isNull);
    });
  });
}

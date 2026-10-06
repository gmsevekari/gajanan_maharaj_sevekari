import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry_details.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_entry_edit_dialog.dart';

void main() {
  Widget createDialogWidget({
    SignupEntry? entry,
    void Function(
      String name,
      String? phone,
      String? email,
      double? pledge,
      String? note,
    )?
    onSave,
    Future<String?> Function(SignupEntryDetails details)? onSaveAsync,
    VoidCallback? onDelete,
    VoidCallback? onReleaseDevice,
    bool showContactActions = true,
    bool requirePhone = false,
    String? defaultCountryCode,
  }) {
    // Most tests only care about the values that were saved.
    final save =
        onSaveAsync ??
        (SignupEntryDetails d) async {
          onSave?.call(d.name, d.phone, d.email, d.pledgeAmount, d.note);
          return null;
        };
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => SignupEntryEditDialog(
                    entry: entry,
                    onSave: save,
                    onDelete: onDelete,
                    onReleaseDevice: onReleaseDevice,
                    showContactActions: showContactActions,
                    requirePhone: requirePhone,
                    defaultCountryCode: defaultCountryCode,
                  ),
                );
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );
  }

  group('SignupEntryEditDialog', () {
    testWidgets('renders add mode when entry is null', (tester) async {
      await tester.pumpWidget(createDialogWidget(onSave: (_, _, _, _, _) {}));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Devotee Entry'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Pledge Amount'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Remove Entry'), findsNothing);
    });

    testWidgets('validates required name field', (tester) async {
      await tester.pumpWidget(createDialogWidget(onSave: (_, _, _, _, _) {}));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);
    });

    testWidgets('submits new entry data on save', (tester) async {
      String? savedName;
      String? savedPhone;
      String? savedEmail;
      double? savedPledge;
      String? savedNote;

      await tester.pumpWidget(
        createDialogWidget(
          onSave: (name, phone, email, pledge, note) {
            savedName = name;
            savedPhone = phone;
            savedEmail = email;
            savedPledge = pledge;
            savedNote = note;
          },
        ),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('entryNameField')),
        'Devotee Name',
      );
      await tester.enterText(
        find.byKey(const Key('entryPhoneField')),
        '1234567890',
      );
      await tester.enterText(
        find.byKey(const Key('entryEmailField')),
        'test@example.com',
      );
      await tester.enterText(find.byKey(const Key('entryPledgeField')), '101');
      await tester.enterText(
        find.byKey(const Key('entryNoteField')),
        'Special seva',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedName, 'Devotee Name');
      expect(savedPhone, '11234567890');
      expect(savedEmail, 'test@example.com');
      expect(savedPledge, 101.0);
      expect(savedNote, 'Special seva');
      expect(find.text('Add Devotee Entry'), findsNothing); // Dialog closed
    });

    group('phone number with country code', () {
      Future<void> open(
        WidgetTester tester, {
        SignupEntry? entry,
        String? defaultCountryCode,
        void Function(String, String?, String?, double?, String?)? onSave,
      }) async {
        await tester.pumpWidget(
          createDialogWidget(
            entry: entry,
            defaultCountryCode: defaultCountryCode,
            onSave: onSave ?? (_, _, _, _, _) {},
          ),
        );
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
      }

      String codeText(WidgetTester tester) => tester
          .widget<TextFormField>(find.byKey(const Key('entryCountryCodeField')))
          .controller!
          .text;

      String numberText(WidgetTester tester) => tester
          .widget<TextFormField>(find.byKey(const Key('entryPhoneField')))
          .controller!
          .text;

      testWidgets('prefills the default country code, +1 unless told '
          'otherwise', (tester) async {
        await open(tester);
        expect(codeText(tester), '+1');
      });

      testWidgets('prefills the group\'s default country code', (tester) async {
        String? savedPhone;
        await open(
          tester,
          defaultCountryCode: '+91',
          onSave: (_, phone, _, _, _) => savedPhone = phone,
        );
        expect(codeText(tester), '+91');

        await tester.enterText(find.byKey(const Key('entryNameField')), 'A');
        await tester.enterText(
          find.byKey(const Key('entryPhoneField')),
          '9876543210',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(savedPhone, '919876543210');
      });

      testWidgets('saves no phone when the number is left blank', (
        tester,
      ) async {
        var saved = false;
        String? savedPhone = 'unset';
        await open(
          tester,
          onSave: (_, phone, _, _, _) {
            saved = true;
            savedPhone = phone;
          },
        );

        await tester.enterText(find.byKey(const Key('entryNameField')), 'A');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(saved, isTrue);
        expect(savedPhone, isNull);
      });

      testWidgets('blocks a number that is too short for its code', (
        tester,
      ) async {
        var saved = false;
        await open(tester, onSave: (_, _, _, _, _) => saved = true);

        await tester.enterText(find.byKey(const Key('entryNameField')), 'A');
        await tester.enterText(
          find.byKey(const Key('entryPhoneField')),
          '12345',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a valid phone number'), findsOneWidget);
        expect(saved, isFalse);
      });

      testWidgets('blocks an invalid country code', (tester) async {
        var saved = false;
        await open(tester, onSave: (_, _, _, _, _) => saved = true);

        await tester.enterText(find.byKey(const Key('entryNameField')), 'A');
        await tester.enterText(
          find.byKey(const Key('entryCountryCodeField')),
          '44',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('!'), findsOneWidget);
        expect(saved, isFalse);
      });

      testWidgets('splits a stored number into its code and number when '
          'editing', (tester) async {
        final entry = SignupEntry(
          id: 'e',
          slotId: 's',
          name: 'Existing',
          phone: '+441234567890',
          joinedAt: DateTime.now(),
        );
        await open(tester, entry: entry, defaultCountryCode: '+1');

        expect(codeText(tester), '+44');
        expect(numberText(tester), '1234567890');
      });

      testWidgets('splits a number stored as digits only into its code and '
          'number, and saves it back the same way', (tester) async {
        final entry = SignupEntry(
          id: 'e',
          slotId: 's',
          name: 'Existing',
          phone: '14255551234',
          joinedAt: DateTime.now(),
        );
        String? savedPhone;
        await open(
          tester,
          entry: entry,
          defaultCountryCode: '+91',
          onSave: (_, phone, _, _, _) => savedPhone = phone,
        );

        expect(codeText(tester), '+1');
        expect(numberText(tester), '4255551234');

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(savedPhone, '14255551234');
      });

      testWidgets('keeps a number saved without a code under the default '
          'code when editing', (tester) async {
        final entry = SignupEntry(
          id: 'e',
          slotId: 's',
          name: 'Existing',
          phone: '9876543210',
          joinedAt: DateTime.now(),
        );
        String? savedPhone;
        await open(
          tester,
          entry: entry,
          defaultCountryCode: '+91',
          onSave: (_, phone, _, _, _) => savedPhone = phone,
        );

        expect(codeText(tester), '+91');
        expect(numberText(tester), '9876543210');

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(savedPhone, '919876543210');
      });
    });

    testWidgets('renders edit mode with pre-filled fields and delete button', (
      tester,
    ) async {
      final entry = SignupEntry(
        id: 'entry_1',
        slotId: 'slot_1',
        name: 'Existing Devotee',
        phone: '9876543210',
        email: 'devotee@test.com',
        pledgeAmount: 51.0,
        note: 'Bringing prasad',
        joinedAt: DateTime.now(),
      );

      var deleteCalled = false;

      await tester.pumpWidget(
        createDialogWidget(
          entry: entry,
          onSave: (_, _, _, _, _) {},
          onDelete: () => deleteCalled = true,
        ),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Entry'), findsOneWidget);
      expect(find.text('Existing Devotee'), findsOneWidget);
      expect(find.text('9876543210'), findsNWidgets(2));
      expect(find.text('devotee@test.com'), findsOneWidget);
      expect(find.text('51'), findsOneWidget);
      expect(find.text('Bringing prasad'), findsOneWidget);

      // Contact actions present
      expect(find.byTooltip('Text'), findsOneWidget);
      expect(find.byTooltip('WhatsApp'), findsOneWidget);

      // Delete button triggers confirmation
      expect(find.text('Remove Entry'), findsOneWidget);
      await tester.tap(find.text('Remove Entry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to remove this entry?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    group('when a devotee edits their own entry', () {
      final entry = SignupEntry(
        id: 'entry_1',
        slotId: 'slot_1',
        name: 'Jane Devotee',
        phone: '+14255551234',
        email: 'jane@example.com',
        pledgeAmount: 25,
        note: 'Sweets',
        joinedAt: DateTime.utc(2026),
      );

      Future<void> open(
        WidgetTester tester, {
        void Function(String, String?, String?, double?, String?)? onSave,
        Future<String?> Function(SignupEntryDetails)? onSaveAsync,
      }) async {
        await tester.pumpWidget(
          createDialogWidget(
            entry: entry,
            onSave: onSave,
            onSaveAsync: onSaveAsync,
            showContactActions: false,
            requirePhone: true,
          ),
        );
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
      }

      testWidgets('hides the contact buttons and the duplicate phone line', (
        tester,
      ) async {
        await open(tester);

        expect(find.byTooltip('Text'), findsNothing);
        expect(find.byTooltip('WhatsApp'), findsNothing);
        // The number appears once, in its field, not also as a header line.
        expect(find.text('4255551234'), findsOneWidget);
        expect(find.text('+14255551234'), findsNothing);
        expect(find.byType(Divider), findsNothing);
      });

      testWidgets('shows every editable field, prefilled, and no Remove', (
        tester,
      ) async {
        await open(tester);

        expect(find.text('Edit Entry'), findsOneWidget);
        expect(find.text('Jane Devotee'), findsOneWidget);
        expect(find.text('jane@example.com'), findsOneWidget);
        expect(find.text('25'), findsOneWidget);
        expect(find.text('Sweets'), findsOneWidget);
        expect(find.text('Remove Entry'), findsNothing);
      });

      testWidgets('saves the changed, trimmed values', (tester) async {
        String? name;
        String? phone;
        String? email;
        double? pledge;
        String? note;
        await open(
          tester,
          onSave: (n, p, e, pl, no) {
            name = n;
            phone = p;
            email = e;
            pledge = pl;
            note = no;
          },
        );

        await tester.enterText(
          find.byKey(const Key('entryNameField')),
          '  Jane Smith ',
        );
        await tester.enterText(
          find.byKey(const Key('entryPhoneField')),
          '4255559999',
        );
        await tester.enterText(find.byKey(const Key('entryEmailField')), ' ');
        await tester.enterText(find.byKey(const Key('entryPledgeField')), '');
        await tester.enterText(find.byKey(const Key('entryNoteField')), '');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(name, 'Jane Smith');
        expect(phone, '14255559999');
        expect(email, isNull);
        expect(pledge, isNull);
        expect(note, isNull);
      });

      testWidgets('blocks an empty name', (tester) async {
        var saved = false;
        await open(tester, onSave: (_, _, _, _, _) => saved = true);

        await tester.enterText(find.byKey(const Key('entryNameField')), '  ');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a name'), findsOneWidget);
        expect(saved, isFalse);
      });

      testWidgets('fits a 360px screen at large text without overflow', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await open(tester);

        expect(tester.takeException(), isNull);
      });

      testWidgets('keeps the dialog open and the input when saving fails, '
          'showing the message under the form', (tester) async {
        var calls = 0;
        await open(
          tester,
          onSaveAsync: (d) async {
            calls++;
            return calls == 1 ? 'That number is taken' : null;
          },
        );

        await tester.enterText(
          find.byKey(const Key('entryNameField')),
          'Jane Smith',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('That number is taken'), findsOneWidget);
        expect(find.text('Edit Entry'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);
        // Save can be pressed again, and success closes the dialog and
        // clears the message.
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(calls, 2);
        expect(find.text('Edit Entry'), findsNothing);
      });

      testWidgets('disables Save and Cancel while the save is in flight', (
        tester,
      ) async {
        final done = Completer<String?>();
        await open(tester, onSaveAsync: (_) => done.future);

        await tester.tap(find.text('Save'));
        await tester.pump();

        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Save'),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
              .onPressed,
          isNull,
        );

        done.complete(null);
        await tester.pumpAndSettle();
        expect(find.text('Edit Entry'), findsNothing);
      });

      testWidgets('requires a phone number', (tester) async {
        var saved = false;
        await open(tester, onSave: (_, _, _, _, _) => saved = true);

        await tester.enterText(find.byKey(const Key('entryPhoneField')), '');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Phone number is required'), findsOneWidget);
        expect(saved, isFalse);
      });
    });

    testWidgets('pre-fills a fractional pledge amount without trimming it', (
      tester,
    ) async {
      final entry = SignupEntry(
        id: 'entry_2',
        slotId: 'slot_1',
        name: 'Devotee With Cents',
        pledgeAmount: 50.5,
        joinedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createDialogWidget(entry: entry, onSave: (_, _, _, _, _) {}),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('50.5'), findsOneWidget);
    });

    group('input limits', () {
      int? maxLengthOf(WidgetTester tester, String key) => tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(Key(key)),
              matching: find.byType(TextField),
            ),
          )
          .maxLength;

      Future<void> openAdd(WidgetTester tester) async {
        await tester.pumpWidget(createDialogWidget(onSave: (_, _, _, _, _) {}));
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
      }

      testWidgets('stops name, email and note at what Firestore accepts', (
        tester,
      ) async {
        await openAdd(tester);

        expect(maxLengthOf(tester, 'entryNameField'), 99);
        expect(maxLengthOf(tester, 'entryEmailField'), 199);
        expect(maxLengthOf(tester, 'entryNoteField'), 499);
        // The counters are hidden to keep the form compact.
        expect(find.text('0/99'), findsNothing);
      });

      testWidgets('rejects a pledge that is not a finite amount up to the '
          'limit', (tester) async {
        var saved = false;
        await tester.pumpWidget(
          createDialogWidget(onSave: (_, _, _, _, _) => saved = true),
        );
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('entryNameField')), 'Jane');

        for (final bad in ['NaN', 'Infinity', '-1', '1000001', 'abc']) {
          await tester.enterText(
            find.byKey(const Key('entryPledgeField')),
            bad,
          );
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
          expect(
            find.text('Please enter a valid amount'),
            findsOneWidget,
            reason: bad,
          );
        }
        expect(saved, isFalse);

        await tester.enterText(
          find.byKey(const Key('entryPledgeField')),
          '1000000',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(saved, isTrue);
      });

      testWidgets('rejects an email that is not an address but allows a '
          'blank one', (tester) async {
        var saved = false;
        await tester.pumpWidget(
          createDialogWidget(onSave: (_, _, _, _, _) => saved = true),
        );
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('entryNameField')), 'Jane');
        await tester.enterText(
          find.byKey(const Key('entryEmailField')),
          'not-an-email',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a valid email address'), findsOneWidget);
        expect(saved, isFalse);

        await tester.enterText(find.byKey(const Key('entryEmailField')), '');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(saved, isTrue);
      });

      testWidgets('lets an admin leave the phone blank', (tester) async {
        var saved = false;
        await tester.pumpWidget(
          createDialogWidget(onSave: (_, _, _, _, _) => saved = true),
        );
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('entryNameField')), 'Jane');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(saved, isTrue);
      });
    });

    group('release device link', () {
      final entry = SignupEntry(
        id: 'e1',
        slotId: 's1',
        name: 'Jane',
        phone: '+14255551234',
        deviceId: 'device_a',
        joinedAt: DateTime.utc(2026),
      );

      Future<void> open(
        WidgetTester tester, {
        VoidCallback? onReleaseDevice,
        VoidCallback? onDelete,
      }) async {
        await tester.pumpWidget(
          createDialogWidget(
            entry: entry,
            onSave: (_, _, _, _, _) {},
            onReleaseDevice: onReleaseDevice,
            onDelete: onDelete,
          ),
        );
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
      }

      testWidgets('is not offered without a callback', (tester) async {
        await open(tester);

        expect(find.text('Release Device Link'), findsNothing);
      });

      testWidgets('asks first, and changes nothing when declined', (
        tester,
      ) async {
        var released = false;
        await open(tester, onReleaseDevice: () => released = true);

        await tester.ensureVisible(find.text('Release Device Link'));
        await tester.tap(find.text('Release Device Link'));
        await tester.pumpAndSettle();

        expect(find.text('Release device link?'), findsOneWidget);
        expect(
          find.text(
            'This entry will no longer belong to the devotee\'s device. '
            'They can claim it again with their phone number. '
            'Unsaved changes in this form will be lost.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        expect(released, isFalse);
        expect(find.text('Edit Entry'), findsOneWidget);
      });

      testWidgets('releases and closes the dialog when confirmed', (
        tester,
      ) async {
        var released = 0;
        await open(tester, onReleaseDevice: () => released++);

        await tester.ensureVisible(find.text('Release Device Link'));
        await tester.tap(find.text('Release Device Link'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(released, 1);
        expect(find.text('Edit Entry'), findsNothing);
      });

      testWidgets('fits alongside Remove at 360px and large text', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await open(tester, onReleaseDevice: () {}, onDelete: () {});

        expect(tester.takeException(), isNull);
      });
    });
  });
}

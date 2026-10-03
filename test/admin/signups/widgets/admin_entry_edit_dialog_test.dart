import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_entry_edit_dialog.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';

void main() {
  Widget createDialogWidget({
    SignupEntry? entry,
    required void Function(
      String name,
      String? phone,
      String? email,
      double? pledge,
      String? note,
    )
    onSave,
    VoidCallback? onDelete,
    String? defaultCountryCode,
  }) {
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
                  builder: (_) => AdminEntryEditDialog(
                    entry: entry,
                    onSave: onSave,
                    onDelete: onDelete,
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

  group('AdminEntryEditDialog', () {
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
      expect(savedPhone, '+11234567890');
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

        expect(savedPhone, '+919876543210');
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
        expect(savedPhone, '+919876543210');
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
  });
}

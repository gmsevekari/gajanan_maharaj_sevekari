import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/my_signups_section.dart';

void main() {
  Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  SignupSlot buildSlot({
    String id = 's1',
    String labelEn = 'Week 1',
    String labelMr = 'आठवडा १',
  }) {
    return SignupSlot(
      id: id,
      labelEn: labelEn,
      labelMr: labelMr,
      capacity: 3,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );
  }

  testWidgets('shows the given empty message when there are no entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: const [],
          slots: const [],
          onCancelEntry: (_) {},
          onEditEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('renders each entry with its slot label and a Cancel button', (
    tester,
  ) async {
    final entries = [
      SignupEntry(
        id: 'e1',
        slotId: 's1',
        name: 'Jane',
        joinedAt: DateTime.now(),
      ),
      SignupEntry(
        id: 'e2',
        slotId: 's2',
        name: 'John',
        joinedAt: DateTime.now(),
      ),
    ];
    final slots = [
      buildSlot(id: 's1', labelEn: 'Week 1'),
      buildSlot(id: 's2', labelEn: 'Week 2'),
    ];

    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: entries,
          slots: slots,
          onCancelEntry: (_) {},
          onEditEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    expect(find.text('Jane'), findsOneWidget);
    expect(find.text('Week 1'), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
    expect(find.text('Week 2'), findsOneWidget);
    expect(find.text('Cancel'), findsNWidgets(2));
    expect(find.text('Edit'), findsNWidgets(2));
  });

  testWidgets('leaves out the Cancel button when there is no onCancelEntry', (
    tester,
  ) async {
    final entries = [
      SignupEntry(
        id: 'e1',
        slotId: 's1',
        name: 'Jane',
        joinedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: entries,
          slots: [buildSlot()],
          onEditEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    expect(find.text('Jane'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('falls back to the Marathi slot label when locale is mr', (
    tester,
  ) async {
    final entries = [
      SignupEntry(
        id: 'e1',
        slotId: 's1',
        name: 'Jane',
        joinedAt: DateTime.now(),
      ),
    ];
    final slots = [buildSlot(id: 's1', labelMr: 'आठवडा १')];

    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: entries,
          slots: slots,
          onCancelEntry: (_) {},
          onEditEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
        locale: const Locale('mr'),
      ),
    );

    expect(find.text('आठवडा १'), findsOneWidget);
  });

  testWidgets('invokes onCancelEntry with the tapped entry', (tester) async {
    final entry = SignupEntry(
      id: 'e1',
      slotId: 's1',
      name: 'Jane',
      joinedAt: DateTime.now(),
    );
    SignupEntry? cancelled;

    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: [entry],
          slots: [buildSlot()],
          onCancelEntry: (e) => cancelled = e,
          onEditEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(cancelled, equals(entry));
  });

  testWidgets('invokes onEditEntry with the tapped entry', (tester) async {
    final entry = SignupEntry(
      id: 'e1',
      slotId: 's1',
      name: 'Jane',
      joinedAt: DateTime.now(),
    );
    SignupEntry? edited;

    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: [entry],
          slots: [buildSlot()],
          onCancelEntry: (_) {},
          onEditEntry: (e) => edited = e,
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(edited, equals(entry));
  });

  testWidgets('leaves out the Edit button when there is no onEditEntry', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: [
            SignupEntry(
              id: 'e1',
              slotId: 's1',
              name: 'Jane',
              joinedAt: DateTime.now(),
            ),
          ],
          slots: [buildSlot()],
          onCancelEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    expect(find.text('Jane'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('shows the entry\'s phone and email under the slot label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: [
            SignupEntry(
              id: 'e1',
              slotId: 's1',
              name: 'Jane',
              phone: '+14255551234',
              email: 'jane@example.com',
              joinedAt: DateTime.now(),
            ),
          ],
          slots: [buildSlot()],
          onCancelEntry: (_) {},
          onEditEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    expect(find.text('+14255551234'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
  });

  testWidgets('shows no phone or email line when the entry has none', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: [
            SignupEntry(
              id: 'e1',
              slotId: 's1',
              name: 'Jane',
              phone: '',
              email: '  ',
              joinedAt: DateTime.now(),
            ),
          ],
          slots: [buildSlot()],
          onCancelEntry: (_) {},
          onEditEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    // Name and slot label only.
    expect(find.byType(Text), findsNWidgets(4)); // name, slot, Edit, Cancel
  });

  testWidgets('keeps both buttons on screen at 360px with large text and '
      'long details', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: [
            SignupEntry(
              id: 'e1',
              slotId: 's1',
              name: 'Jane Elizabeth Devotee-Kulkarni',
              phone: '+14255551234',
              email: 'jane.elizabeth.devotee.kulkarni@example.com',
              joinedAt: DateTime.now(),
            ),
          ],
          slots: [
            buildSlot(labelEn: 'Week 1 - Cooking and serving the prasad'),
          ],
          onCancelEntry: (_) {},
          onEditEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final label in ['Edit', 'Cancel']) {
      expect(tester.getRect(find.text(label)).right, lessThanOrEqualTo(360));
    }
  });

  testWidgets('shows no buttons or empty gap when neither callback is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: [
            SignupEntry(
              id: 'e1',
              slotId: 's1',
              name: 'Jane',
              joinedAt: DateTime.now(),
            ),
          ],
          slots: [buildSlot()],
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(Wrap), findsNothing);
    expect(find.text('Jane'), findsOneWidget);
  });

  testWidgets('gives a long name the full card width at 360px', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: [
            SignupEntry(
              id: 'e1',
              slotId: 's1',
              name: 'Jane Elizabeth Devotee-Kulkarni',
              joinedAt: DateTime.now(),
            ),
          ],
          slots: [buildSlot()],
          onCancelEntry: (_) {},
          onEditEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    // The buttons sit under the details, so they don't squeeze the name:
    // it can use the card (360 less 16 list padding each side, 16 + 8 card
    // padding) rather than losing the width of two buttons.
    final name = find.text('Jane Elizabeth Devotee-Kulkarni');
    expect(tester.getSize(name).width, greaterThan(250));
    expect(
      tester.getTopLeft(find.text('Edit')).dy,
      greaterThan(tester.getBottomLeft(name).dy),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/my_signups_section.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/slot_when_view.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

import '../../../helpers/slot_fixtures.dart';

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

  group('what each card shows', () {
    SignupEntry entry({String? phone, String? email}) => SignupEntry(
      id: 'e1',
      slotId: 's1',
      name: 'Jane',
      phone: phone,
      email: email,
      joinedAt: DateTime.now(),
    );

    Future<void> show(
      WidgetTester tester,
      SignupEntry e,
      List<SignupSlot> slots, {
      Locale locale = const Locale('en'),
    }) => tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: [e],
          slots: slots,
          onCancelEntry: (_) {},
          onEditEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
        locale: locale,
      ),
    );

    testWidgets('shows the name, slot title and date for a full-day slot, '
        'with no time', (tester) async {
      await show(tester, entry(), [
        scheduledSlot(
          id: 's1',
          labelEn: 'Morning Seva',
          start: wallClock(2030, 7, 3),
          end: wallClock(2030, 7, 3, 23, 59),
        ),
      ]);

      expect(find.text('Jane'), findsOneWidget);
      expect(find.text('Morning Seva'), findsOneWidget);
      expect(find.text('Wednesday, July 3'), findsOneWidget);
      expect(find.textContaining(' PT'), findsNothing);
      // name, title, date, Edit, Cancel
      expect(find.byType(Text), findsNWidgets(5));
    });

    testWidgets('adds the time for a slot that is not a full day', (
      tester,
    ) async {
      await show(tester, entry(), [
        scheduledSlot(
          id: 's1',
          start: wallClock(2030, 7, 3, 18),
          end: wallClock(2030, 7, 3, 19, 30),
        ),
      ]);

      expect(find.text('Wednesday, July 3'), findsOneWidget);
      expect(find.text('6:00 PM – 7:30 PM PT'), findsOneWidget);
    });

    testWidgets('shows a range for a slot that spans days', (tester) async {
      await show(tester, entry(), [
        scheduledSlot(
          id: 's1',
          start: wallClock(2030, 7, 1, 18),
          end: wallClock(2030, 7, 3, 12),
        ),
      ]);

      expect(find.text('Jul 1, 6:00 PM – Jul 3, 12:00 PM PT'), findsOneWidget);
    });

    testWidgets('shows the time in the slot\'s own zone', (tester) async {
      await show(tester, entry(), [
        scheduledSlot(
          id: 's1',
          timezone: EventTimezone.india,
          start: wallClock(2030, 7, 3, 18, 0, EventTimezone.india),
          end: wallClock(2030, 7, 3, 19, 30, EventTimezone.india),
        ),
      ]);

      expect(find.text('6:00 PM – 7:30 PM IST'), findsOneWidget);
    });

    testWidgets('keeps the date in English under a Marathi locale', (
      tester,
    ) async {
      await show(tester, entry(), [
        scheduledSlot(
          id: 's1',
          start: wallClock(2030, 7, 3, 18),
          end: wallClock(2030, 7, 3, 19, 30),
        ),
      ], locale: const Locale('mr'));

      expect(find.text('Wednesday, July 3'), findsOneWidget);
      expect(find.text('6:00 PM – 7:30 PM PT'), findsOneWidget);
    });

    testWidgets('shows no date for a slot with no schedule or a slot that is '
        'gone', (tester) async {
      await show(tester, entry(), [buildSlot()]);
      expect(find.byType(SlotWhenView), findsNothing);

      await show(tester, entry(), const []);
      expect(find.byType(SlotWhenView), findsNothing);
      expect(find.text('Jane'), findsOneWidget);
    });

    testWidgets('never shows the phone number or email', (tester) async {
      await show(
        tester,
        entry(phone: '14255551234', email: 'jane@example.com'),
        [
          scheduledSlot(
            id: 's1',
            start: wallClock(2030, 7, 3),
            end: wallClock(2030, 7, 3, 23, 59),
          ),
        ],
      );

      expect(find.textContaining('4255551234'), findsNothing);
      expect(find.textContaining('jane@example.com'), findsNothing);
      expect(find.textContaining('@'), findsNothing);
    });
  });

  group('pledge amount and note', () {
    Future<void> show(
      WidgetTester tester, {
      double? pledgeAmount,
      String? note,
      SignupSlot? slot,
    }) => tester.pumpWidget(
      wrap(
        MySignupsSection(
          entries: [
            SignupEntry(
              id: 'e1',
              slotId: 's1',
              name: 'Jane',
              pledgeAmount: pledgeAmount,
              note: note,
              joinedAt: DateTime.now(),
            ),
          ],
          slots: [
            slot ??
                scheduledSlot(
                  id: 's1',
                  labelEn: 'Morning Seva',
                  start: wallClock(2030, 7, 3),
                  end: wallClock(2030, 7, 3, 23, 59),
                ),
          ],
          onCancelEntry: (_) {},
          onEditEntry: (_) {},
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    testWidgets('shows a whole-number pledge without a trailing .0', (
      tester,
    ) async {
      await show(tester, pledgeAmount: 51);

      expect(find.text('Pledge Amount: 51'), findsOneWidget);
    });

    testWidgets('keeps a fractional pledge as it is', (tester) async {
      await show(tester, pledgeAmount: 50.5);

      expect(find.text('Pledge Amount: 50.5'), findsOneWidget);
    });

    testWidgets('shows a pledge of 0, since one was entered', (tester) async {
      await show(tester, pledgeAmount: 0);

      expect(find.text('Pledge Amount: 0'), findsOneWidget);
    });

    testWidgets('shows the note', (tester) async {
      await show(tester, note: 'Bringing sweets');

      expect(find.text('Note: Bringing sweets'), findsOneWidget);
    });

    testWidgets('trims the note', (tester) async {
      await show(tester, note: '  Bringing sweets \n');

      expect(find.text('Note: Bringing sweets'), findsOneWidget);
    });

    testWidgets('shows neither when the entry has none, or the note is '
        'blank', (tester) async {
      await show(tester);
      expect(find.textContaining('Pledge Amount'), findsNothing);
      expect(find.textContaining('Note'), findsNothing);

      await show(tester, note: '   ');
      expect(find.textContaining('Note'), findsNothing);
    });

    testWidgets('lists them under the date, pledge first, then the note', (
      tester,
    ) async {
      await show(tester, pledgeAmount: 25, note: 'Sweets');

      final date = tester.getRect(find.byType(SlotWhenView));
      final pledge = tester.getRect(find.text('Pledge Amount: 25'));
      final note = tester.getRect(find.text('Note: Sweets'));
      final name = tester.getRect(find.text('Jane'));

      expect(pledge.top, greaterThan(date.bottom - 1));
      expect(note.top, greaterThan(pledge.bottom - 1));
      expect(pledge.left, name.left);
      expect(note.left, name.left);
      // The same 4px between each line as above.
      expect(pledge.top - date.bottom, closeTo(4, 0.5));
      expect(note.top - pledge.bottom, closeTo(4, 0.5));
    });

    testWidgets('shows them even when the slot has no date', (tester) async {
      await show(tester, pledgeAmount: 25, note: 'Sweets', slot: buildSlot());

      expect(find.text('Pledge Amount: 25'), findsOneWidget);
      expect(find.text('Note: Sweets'), findsOneWidget);
    });

    testWidgets('cuts a long note to three lines', (tester) async {
      await show(tester, note: 'x ' * 200);

      final text = tester.widget<Text>(find.textContaining('Note: '));
      expect(text.maxLines, 3);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('fits a 360px screen at large text with a long note', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await show(tester, pledgeAmount: 1000000, note: 'y ' * 200);

      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.text('Cancel')).right, lessThanOrEqualTo(360));
    });
  });

  group('card layout', () {
    Future<void> showCard(WidgetTester tester, {bool withActions = true}) =>
        tester.pumpWidget(
          wrap(
            MySignupsSection(
              entries: [
                SignupEntry(
                  id: 'e1',
                  slotId: 's1',
                  name: 'Abhishek',
                  joinedAt: DateTime.now(),
                ),
              ],
              slots: [
                scheduledSlot(
                  id: 's1',
                  labelEn: 'Day 4: Royal Blue',
                  start: wallClock(2030, 7, 3),
                  end: wallClock(2030, 7, 3, 23, 59),
                ),
              ],
              onCancelEntry: withActions ? (_) {} : null,
              onEditEntry: withActions ? (_) {} : null,
              emptyMessage: 'Nothing here yet',
            ),
          ),
        );

    testWidgets('lines up the name, title and date on the same left edge and '
        'spaces them evenly', (tester) async {
      await showCard(tester);

      final name = tester.getRect(find.text('Abhishek'));
      final title = tester.getRect(find.text('Day 4: Royal Blue'));
      final date = tester.getRect(find.byIcon(Icons.calendar_today));
      final dateText = tester.getRect(find.text('Wednesday, July 3'));

      expect(title.left, name.left);
      expect(date.left, name.left);
      // The same gap between name and title as between title and date.
      expect(
        title.top - name.bottom,
        closeTo(dateText.top - title.bottom, 0.5),
      );
    });

    testWidgets('gives the card equal space left and right of its text', (
      tester,
    ) async {
      await showCard(tester);

      final card = tester.getRect(find.byType(Card));
      final name = tester.getRect(find.text('Abhishek'));
      final cancel = tester.getRect(find.text('Cancel'));

      expect(name.left - card.left, 16);
      expect(card.right - cancel.right, closeTo(16, 0.5));
    });

    testWidgets('keeps the same space above the name as below the last '
        'content, with or without buttons', (tester) async {
      await showCard(tester, withActions: false);

      // The card's own surface, without the 8px margin the Card adds around it.
      final card = tester.getRect(
        find
            .descendant(of: find.byType(Card), matching: find.byType(Material))
            .first,
      );
      final name = tester.getRect(find.text('Abhishek'));
      final date = tester.getRect(find.byType(SlotWhenView));

      expect(name.top - card.top, 16);
      expect(card.bottom - date.bottom, closeTo(16, 0.5));
    });

    testWidgets('puts the buttons a clear step below the details', (
      tester,
    ) async {
      await showCard(tester);

      final date = tester.getRect(find.byType(SlotWhenView));
      final edit = tester.getRect(find.byType(TextButton).first);

      expect(edit.top - date.bottom, greaterThanOrEqualTo(4));
    });
  });

  testWidgets('keeps both buttons on screen at 360px with large text and '
      'a long date range', (tester) async {
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
              joinedAt: DateTime.now(),
            ),
          ],
          slots: [
            scheduledSlot(
              id: 's1',
              labelEn: 'Week 1 - Cooking and serving the prasad',
              start: wallClock(2030, 12, 28, 18),
              end: wallClock(2031, 1, 3, 12),
            ),
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

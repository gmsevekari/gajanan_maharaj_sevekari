import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_entries_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:provider/provider.dart';

import '../../helpers/slot_fixtures.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;
  late String signupId;
  var nextSortOrder = 0;

  final future = DateTime(2099, 3, 15);
  final farFuture = DateTime(2099, 4, 1);
  final past = DateTime(2020, 1, 10);

  setUp(() async {
    nextSortOrder = 0;
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
    final now = DateTime.now();
    signupId = await service.createSignup(
      Signup(
        titleEn: 'Sunday Prasad Seva',
        titleMr: 'रविवार प्रसाद सेवा',
        groupId: 'group_1',
        status: SignupStatus.published,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      ),
    );
  });

  Widget wrap(Widget child, {Locale? locale}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text(settings.name ?? '')),
            body: Text('Navigated to: ${settings.name}'),
          ),
        ),
        home: child,
      ),
    );
  }

  Widget screen({Locale? locale}) => wrap(
    SignupEntriesScreen(
      signupId: signupId,
      firestore: firestore,
      signupService: service,
    ),
    locale: locale,
  );

  Future<String> addSlot({
    String labelEn = 'Week 1',
    String labelMr = 'आठवडा १',
    DateTime? date,
    DateTime? start,
    DateTime? end,
    String timezone = EventTimezone.pacific,
    int capacity = 3,
  }) {
    // [date] is an all-day slot on that calendar day; [start] and [end] give
    // an exact range.
    final from =
        start ??
        (date == null ? null : wallClock(date.year, date.month, date.day));
    final to =
        end ??
        (date == null
            ? null
            : wallClock(date.year, date.month, date.day, 23, 59));
    return service.addSlot(
      signupId,
      SignupSlot(
        labelEn: labelEn,
        labelMr: labelMr,
        startAt: from,
        endAt: to,
        timezone: timezone,
        capacity: capacity,
        sortOrder: nextSortOrder++,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// The cells of every entry row, a cell's lines joined with newlines. The
  /// first Table is the header; each slot then gets a Table of its own, so
  /// rows are collected across them.
  List<List<String?>> tableRows(WidgetTester tester) {
    String cellText(Widget cell) => tester
        .widgetList<Text>(
          find.descendant(of: find.byWidget(cell), matching: find.byType(Text)),
        )
        .map((text) => text.data)
        .join('\n');

    return [
      for (final table in tester.widgetList<Table>(find.byType(Table)).skip(1))
        for (final row in table.children) row.children.map(cellText).toList(),
    ];
  }

  Color? groupColor(WidgetTester tester, int index) {
    final box = tester.widget<Container>(
      find.byKey(Key('entriesGroup_$index')),
    );
    return (box.decoration! as BoxDecoration).color;
  }

  testWidgets('shows the empty message when there are no entries', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('Entries'), findsOneWidget);
    expect(find.text('No one has signed up yet'), findsOneWidget);
    expect(find.byType(Table), findsNothing);
  });

  testWidgets('lists upcoming entries sorted by date, then by slot order', (
    tester,
  ) async {
    final slot1 = await addSlot(labelEn: 'Week 1', date: future, capacity: 3);
    final slot2 = await addSlot(
      labelEn: 'Week 2',
      date: farFuture,
      capacity: 2,
    );
    final slot3 = await addSlot(labelEn: 'Week 3', capacity: 1);
    final slot4 = await addSlot(labelEn: 'Week 4', date: future, capacity: 1);
    await service.claimSlot(signupId: signupId, slotId: slot1, name: 'Jane');
    await service.claimSlot(signupId: signupId, slotId: slot2, name: 'Amit');
    await service.claimSlot(signupId: signupId, slotId: slot3, name: 'Priya');
    await service.claimSlot(signupId: signupId, slotId: slot4, name: 'Anil');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    // Sorted by slot date (slot3's null date sorts last); slot1 and slot4
    // tie on date and fall back to the slots' own order.
    expect(tableRows(tester), [
      ['Sunday, March 15', 'Week 1', 'Jane'],
      ['Sunday, March 15', 'Week 4', 'Anil'],
      ['Wednesday, April 1', 'Week 2', 'Amit'],
      ['-', 'Week 3', 'Priya'],
    ]);
  });

  testWidgets(
    'keeps one slot\'s entries together and shows its date and title once',
    (tester) async {
      final first = await addSlot(labelEn: 'Morning', date: future);
      final second = await addSlot(labelEn: 'Evening', date: future);
      // Alphabetical order across slots would interleave these: Amy, Bob, Zoe.
      await service.claimSlot(signupId: signupId, slotId: second, name: 'Amy');
      await service.claimSlot(signupId: signupId, slotId: first, name: 'Zoe');
      await service.claimSlot(signupId: signupId, slotId: first, name: 'Bob');

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      // The date and title appear once per slot, on its first row only.
      expect(tableRows(tester), [
        ['Sunday, March 15', 'Morning', 'Bob'],
        ['', '', 'Zoe'],
        ['Sunday, March 15', 'Evening', 'Amy'],
      ]);
    },
  );

  group('date cell time range', () {
    Future<void> claimAndShow(
      WidgetTester tester,
      String slotId, {
      List<String> names = const ['Jane'],
    }) async {
      for (final name in names) {
        await service.claimSlot(signupId: signupId, slotId: slotId, name: name);
      }
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
    }

    testWidgets('shows the time range under the date for a timed slot', (
      tester,
    ) async {
      final slotId = await addSlot(
        start: wallClock(2099, 7, 3, 18),
        end: wallClock(2099, 7, 3, 19, 30),
      );
      await claimAndShow(tester, slotId);

      expect(tableRows(tester), [
        ['Friday, July 3\n6:00 PM – 7:30 PM PT', 'Week 1', 'Jane'],
      ]);
      // A table cell, not a card: no calendar icon.
      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });

    testWidgets('shows a multi-day timed range on one line', (tester) async {
      final slotId = await addSlot(
        start: wallClock(2099, 7, 1, 18),
        end: wallClock(2099, 7, 3, 12),
      );
      await claimAndShow(tester, slotId);

      expect(tableRows(tester), [
        ['Jul 1, 6:00 PM – Jul 3, 12:00 PM PT', 'Week 1', 'Jane'],
      ]);
    });

    testWidgets('shows the time in the slot\'s own zone', (tester) async {
      final slotId = await addSlot(
        timezone: EventTimezone.india,
        start: wallClock(2099, 7, 3, 18, 0, EventTimezone.india),
        end: wallClock(2099, 7, 3, 19, 30, EventTimezone.india),
      );
      await claimAndShow(tester, slotId);

      expect(tableRows(tester), [
        ['Friday, July 3\n6:00 PM – 7:30 PM IST', 'Week 1', 'Jane'],
      ]);
    });

    testWidgets('shows the date and time only on a slot\'s first row', (
      tester,
    ) async {
      final slotId = await addSlot(
        start: wallClock(2099, 7, 3, 18),
        end: wallClock(2099, 7, 3, 19, 30),
      );
      await claimAndShow(tester, slotId, names: ['Amy', 'Bob']);

      expect(tableRows(tester), [
        ['Friday, July 3\n6:00 PM – 7:30 PM PT', 'Week 1', 'Amy'],
        ['', '', 'Bob'],
      ]);
      expect(find.text('6:00 PM – 7:30 PM PT'), findsOneWidget);
    });

    testWidgets('shows a dash for a slot with no schedule', (tester) async {
      final slotId = await addSlot();
      await claimAndShow(tester, slotId);

      expect(tableRows(tester), [
        ['-', 'Week 1', 'Jane'],
      ]);
    });

    testWidgets('wraps a long multi-day range at 360px without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final slotId = await addSlot(
        start: wallClock(2099, 12, 28, 18),
        end: wallClock(2100, 1, 3, 12),
      );
      await claimAndShow(tester, slotId);

      expect(tester.takeException(), isNull);
      expect(
        find.text('Dec 28, 2099, 6:00 PM – Jan 3, 2100, 12:00 PM PT'),
        findsOneWidget,
      );
    });

    testWidgets('stays English under a Marathi locale', (tester) async {
      final slotId = await addSlot(
        start: wallClock(2099, 7, 3, 18),
        end: wallClock(2099, 7, 3, 19, 30),
      );
      await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

      await tester.pumpWidget(screen(locale: const Locale('mr')));
      await tester.pumpAndSettle();

      expect(find.text('6:00 PM – 7:30 PM PT'), findsOneWidget);
    });
  });

  testWidgets('gives each slot one background and alternates between slots', (
    tester,
  ) async {
    final a = await addSlot(labelEn: 'Morning', date: future);
    final b = await addSlot(labelEn: 'Evening', date: future);
    final c = await addSlot(labelEn: 'Night', date: farFuture);
    await service.claimSlot(signupId: signupId, slotId: a, name: 'Amy');
    await service.claimSlot(signupId: signupId, slotId: a, name: 'Bob');
    await service.claimSlot(signupId: signupId, slotId: b, name: 'Cat');
    await service.claimSlot(signupId: signupId, slotId: c, name: 'Dan');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    // Three slots -> three groups; the two entries of the first slot share
    // one group (one Table of two rows).
    expect(find.byKey(const Key('entriesGroup_0')), findsOneWidget);
    expect(find.byKey(const Key('entriesGroup_1')), findsOneWidget);
    expect(find.byKey(const Key('entriesGroup_2')), findsOneWidget);
    expect(find.byKey(const Key('entriesGroup_3')), findsNothing);
    final firstGroupTable = tester.widget<Table>(
      find.descendant(
        of: find.byKey(const Key('entriesGroup_0')),
        matching: find.byType(Table),
      ),
    );
    expect(firstGroupTable.children, hasLength(2));

    // Neighbouring slots differ, every other slot repeats.
    expect(groupColor(tester, 0), isNot(groupColor(tester, 1)));
    expect(groupColor(tester, 2), groupColor(tester, 0));
  });

  testWidgets('shows only Date, Title and Name columns', (tester) async {
    final slotId = await addSlot(date: future);
    await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Available Slots'), findsNothing);
    final header = tester.widgetList<Table>(find.byType(Table)).first;
    expect(header.children.single.children, hasLength(3));
  });

  testWidgets('puts entries for past slots on the Past tab only', (
    tester,
  ) async {
    final pastSlot = await addSlot(labelEn: 'Old Week', date: past);
    final futureSlot = await addSlot(labelEn: 'New Week', date: future);
    await service.claimSlot(
      signupId: signupId,
      slotId: pastSlot,
      name: 'Past Person',
    );
    await service.claimSlot(
      signupId: signupId,
      slotId: futureSlot,
      name: 'Future Person',
    );

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('Future Person'), findsOneWidget);
    expect(find.text('Past Person'), findsNothing);

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('Past Person'), findsOneWidget);
    expect(find.text('Future Person'), findsNothing);
    expect(tableRows(tester), [
      ['Friday, January 10', 'Old Week', 'Past Person'],
    ]);
  });

  testWidgets('shows the empty message on the Past tab when none are past', (
    tester,
  ) async {
    final slotId = await addSlot(date: future);
    await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('No one has signed up yet'), findsOneWidget);
  });

  testWidgets('shows a blank title and dash for an entry whose slot is gone', (
    tester,
  ) async {
    final slotId = await addSlot();
    await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Orphan');
    // Bypass SignupService.deleteSlot's claimed-entry guard to simulate an
    // entry left behind after its slot is gone some other way.
    await firestore
        .collection('signups')
        .doc(signupId)
        .collection('slots')
        .doc(slotId)
        .delete();

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(tableRows(tester), [
      ['-', '', 'Orphan'],
    ]);
  });

  testWidgets('lists an entry whose slot is gone after the entries that have '
      'one', (tester) async {
    final orphanSlot = await addSlot(labelEn: 'Gone', date: future);
    final liveSlot = await addSlot(labelEn: 'Live', date: farFuture);
    await service.claimSlot(
      signupId: signupId,
      slotId: orphanSlot,
      name: 'Orphan',
    );
    await service.claimSlot(signupId: signupId, slotId: liveSlot, name: 'Kept');
    await firestore
        .collection('signups')
        .doc(signupId)
        .collection('slots')
        .doc(orphanSlot)
        .delete();

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    // The orphan's slot would sort first if it still existed (earlier date).
    expect(tableRows(tester).map((row) => row[2]), ['Kept', 'Orphan']);
  });

  testWidgets(
    'shows the Marathi slot label but English UI and dates under mr',
    (tester) async {
      final slotId = await addSlot(date: future);
      await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

      await tester.pumpWidget(screen(locale: const Locale('mr')));
      await tester.pumpAndSettle();

      expect(find.text('Entries'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Available Slots'), findsNothing);
      expect(find.text('Sunday, March 15'), findsOneWidget);
      expect(find.text('आठवडा १'), findsOneWidget);
    },
  );

  testWidgets('falls back to the other language when a slot label is blank', (
    tester,
  ) async {
    final slotId = await addSlot(labelEn: '', labelMr: 'आठवडा १');
    await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('आठवडा १'), findsOneWidget);
  });

  testWidgets('fits a narrow screen and wraps long text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final slotId = await addSlot(
      labelEn: 'A very long slot title that must wrap onto lines',
      date: future,
    );
    await service.claimSlot(
      signupId: signupId,
      slotId: slotId,
      name: 'A devotee with a remarkably long full name',
    );

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final table in find.byType(Table).evaluate()) {
      expect(
        (table.renderObject! as RenderBox).size.width,
        lessThanOrEqualTo(360),
      );
    }
  });

  testWidgets('tab labels contrast with the app bar so the selected tab is '
      'visible', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    final theme = AppTheme.lightTheme;
    expect(tabBar.labelColor, theme.colorScheme.onPrimary);
    expect(tabBar.labelColor, isNot(theme.appBarTheme.backgroundColor));
    expect(tabBar.indicatorColor, theme.colorScheme.onPrimary);
  });

  testWidgets('tapping home icon navigates to home', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Navigated to: /home'), findsOneWidget);
  });

  testWidgets('tapping settings icon navigates to settings', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
          .at(1),
    );
    await tester.pumpAndSettle();

    expect(find.text('Navigated to: /settings'), findsOneWidget);
  });

  testWidgets('does not switch tabs when the content is swiped', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    final controller = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    expect(controller.index, 0);
  });

  group('which tab an entry is on follows the end of its slot', () {
    final now = DateTime.now();

    Future<String> addTimedSlot(
      String label, {
      DateTime? startAt,
      DateTime? endAt,
      int sortOrder = 0,
    }) => service.addSlot(
      signupId,
      SignupSlot(
        labelEn: label,
        labelMr: '',
        startAt: startAt,
        endAt: endAt,
        capacity: 3,
        sortOrder: sortOrder,
        createdAt: DateTime.now(),
      ),
    );

    Future<void> pumpEntryFor(
      WidgetTester tester, {
      DateTime? startAt,
      DateTime? endAt,
    }) async {
      final slotId = await addTimedSlot(
        'Timed Week',
        startAt: startAt,
        endAt: endAt,
      );
      await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
    }

    Future<void> expectOnUpcoming(WidgetTester tester) async {
      expect(find.text('Timed Week'), findsOneWidget);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Timed Week'), findsNothing);
    }

    testWidgets('a slot that started earlier today but ends later is '
        'upcoming', (tester) async {
      await pumpEntryFor(
        tester,
        startAt: now.subtract(const Duration(hours: 1)),
        endAt: now.add(const Duration(hours: 5)),
      );
      await expectOnUpcoming(tester);
    });

    testWidgets('a multi-day slot that is in progress is upcoming', (
      tester,
    ) async {
      await pumpEntryFor(
        tester,
        startAt: now.subtract(const Duration(days: 1)),
        endAt: now.add(const Duration(days: 2)),
      );
      await expectOnUpcoming(tester);
    });

    testWidgets('a slot with a start but no end is upcoming', (tester) async {
      await pumpEntryFor(
        tester,
        startAt: now.subtract(const Duration(days: 10)),
      );
      await expectOnUpcoming(tester);
    });

    testWidgets('a slot that ended earlier today is past', (tester) async {
      await pumpEntryFor(
        tester,
        startAt: now.subtract(const Duration(hours: 5)),
        endAt: now.subtract(const Duration(hours: 1)),
      );

      expect(find.text('Timed Week'), findsNothing);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Timed Week'), findsOneWidget);
    });

    testWidgets('slots on the same day are listed by start time, whatever '
        'their slot order', (tester) async {
      final day = DateTime.now().add(const Duration(days: 4));
      final morning = DateTime(day.year, day.month, day.day, 9);
      final evening = DateTime(day.year, day.month, day.day, 18);
      final eveningId = await addTimedSlot(
        'Evening',
        startAt: evening,
        endAt: evening.add(const Duration(hours: 2)),
        sortOrder: 0,
      );
      final morningId = await addTimedSlot(
        'Morning',
        startAt: morning,
        endAt: morning.add(const Duration(hours: 2)),
        sortOrder: 5,
      );
      await service.claimSlot(
        signupId: signupId,
        slotId: eveningId,
        name: 'Eve',
      );
      await service.claimSlot(
        signupId: signupId,
        slotId: morningId,
        name: 'Mo',
      );
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(tableRows(tester).map((row) => row[2]), ['Mo', 'Eve']);
    });

    testWidgets('a slot with no times sorts after slots that have them', (
      tester,
    ) async {
      final undated = await addTimedSlot('Undated', sortOrder: 0);
      final soon = now.add(const Duration(days: 2));
      final dated = await addTimedSlot(
        'Dated',
        startAt: soon,
        endAt: soon.add(const Duration(hours: 1)),
        sortOrder: 9,
      );
      await service.claimSlot(signupId: signupId, slotId: undated, name: 'U');
      await service.claimSlot(signupId: signupId, slotId: dated, name: 'D');
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(tableRows(tester).map((row) => row[2]), ['D', 'U']);
    });
  });
}

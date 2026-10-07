import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/export_slots_dialog.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6, 12);

  SignupSlot slot(
    String id,
    String label, {
    DateTime? start,
    int claimed = 0,
    int capacity = 5,
    int sortOrder = 0,
    String labelMr = '',
  }) => SignupSlot(
    id: id,
    labelEn: label,
    labelMr: labelMr,
    startAt: start,
    endAt: start?.add(const Duration(hours: 2)),
    timezone: 'America/Los_Angeles',
    capacity: capacity,
    claimedCount: claimed,
    sortOrder: sortOrder,
    createdAt: now,
  );

  final past = slot('past', 'Last Week', start: DateTime.utc(2026, 9, 29, 18));
  final later = slot(
    'later',
    'Later Seva',
    start: DateTime.utc(2026, 10, 20, 18),
    claimed: 2,
  );
  final sooner = slot(
    'sooner',
    'Sooner Seva',
    start: DateTime.utc(2026, 10, 10, 18),
    claimed: 5,
  );
  final undated = slot('undated', 'Whenever Seva', sortOrder: 9);

  /// Opens the dialog from a button and records what it returned.
  Future<void> openDialog(
    WidgetTester tester,
    List<SignupSlot> slots, {
    required void Function(List<SignupSlot>?) onResult,
    Widget Function(Widget child)? wrapChild,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => onResult(
                  await showExportSlotsDialog(
                    context: context,
                    slots: slots,
                    now: now,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Finder tile(String label) => find.widgetWithText(CheckboxListTile, label);
  bool checked(WidgetTester tester, String label) =>
      tester.widget<CheckboxListTile>(tile(label)).value!;
  Finder exportButton() => find.widgetWithText(TextButton, 'Export');

  testWidgets('lists the upcoming slots by date, undated last, no past ones', (
    tester,
  ) async {
    await openDialog(tester, [undated, later, past, sooner], onResult: (_) {});

    expect(find.text('Export Sign Ups'), findsOneWidget);
    expect(find.text('Last Week'), findsNothing);
    final order = ['Sooner Seva', 'Later Seva', 'Whenever Seva'];
    final tops = [for (final l in order) tester.getTopLeft(find.text(l)).dy];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.byType(CheckboxListTile), findsNWidgets(4)); // + select all
  });

  testWidgets('shows each slot with its date and how full it is', (
    tester,
  ) async {
    await openDialog(tester, [sooner, later], onResult: (_) {});

    expect(find.text('Choose the upcoming slots to include.'), findsOneWidget);
    expect(find.textContaining('October 10'), findsOneWidget);
    expect(find.textContaining('October 20'), findsOneWidget);
    expect(find.text('5 of 5 claimed'), findsOneWidget);
    expect(find.text('2 of 5 claimed'), findsOneWidget);
  });

  testWidgets('has every upcoming slot ticked to begin with', (tester) async {
    List<SignupSlot>? result;
    await openDialog(tester, [later, sooner], onResult: (r) => result = r);

    expect(checked(tester, 'Sooner Seva'), isTrue);
    expect(checked(tester, 'Later Seva'), isTrue);
    expect(checked(tester, 'Select all'), isTrue);

    await tester.tap(exportButton());
    await tester.pumpAndSettle();

    expect(result!.map((s) => s.id), ['sooner', 'later']);
  });

  testWidgets('returns only the slots that are still ticked', (tester) async {
    List<SignupSlot>? result;
    await openDialog(tester, [
      sooner,
      later,
      undated,
    ], onResult: (r) => result = r);

    await tester.tap(tile('Later Seva'));
    await tester.pump();
    expect(checked(tester, 'Later Seva'), isFalse);
    await tester.tap(exportButton());
    await tester.pumpAndSettle();

    expect(result!.map((s) => s.id), ['sooner', 'undated']);
  });

  testWidgets('Select all is partly ticked when only some slots are', (
    tester,
  ) async {
    await openDialog(tester, [sooner, later], onResult: (_) {});

    await tester.tap(tile('Later Seva'));
    await tester.pump();

    final selectAll = tester.widget<CheckboxListTile>(tile('Select all'));
    expect(selectAll.tristate, isTrue);
    expect(selectAll.value, isNull);
  });

  testWidgets('Select all unticks everything, then ticks everything', (
    tester,
  ) async {
    await openDialog(tester, [sooner, later], onResult: (_) {});

    await tester.tap(tile('Select all'));
    await tester.pump();
    expect(checked(tester, 'Sooner Seva'), isFalse);
    expect(checked(tester, 'Later Seva'), isFalse);
    expect(checked(tester, 'Select all'), isFalse);

    await tester.tap(tile('Select all'));
    await tester.pump();
    expect(checked(tester, 'Sooner Seva'), isTrue);
    expect(checked(tester, 'Later Seva'), isTrue);
  });

  testWidgets('Select all ticks everything when only some slots were', (
    tester,
  ) async {
    await openDialog(tester, [sooner, later], onResult: (_) {});

    await tester.tap(tile('Later Seva'));
    await tester.pump();
    await tester.tap(tile('Select all'));
    await tester.pump();

    expect(checked(tester, 'Sooner Seva'), isTrue);
    expect(checked(tester, 'Later Seva'), isTrue);
  });

  testWidgets('cannot export with nothing ticked', (tester) async {
    await openDialog(tester, [sooner, later], onResult: (_) {});

    await tester.tap(tile('Select all'));
    await tester.pump();

    expect(tester.widget<TextButton>(exportButton()).onPressed, isNull);
  });

  testWidgets('Cancel closes it with no result', (tester) async {
    var called = false;
    List<SignupSlot>? result = [];
    await openDialog(
      tester,
      [sooner],
      onResult: (r) {
        called = true;
        result = r;
      },
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(result, isNull);
    expect(find.text('Export Sign Ups'), findsNothing);
  });

  testWidgets('says so, with nothing to export, when no slot is upcoming', (
    tester,
  ) async {
    List<SignupSlot>? result = [];
    await openDialog(tester, [past], onResult: (r) => result = r);

    expect(find.text('There are no upcoming slots to export.'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(exportButton(), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('says so when the sign up has no slots at all', (tester) async {
    await openDialog(tester, const [], onResult: (_) {});

    expect(find.text('There are no upcoming slots to export.'), findsOneWidget);
  });

  testWidgets('treats a slot that has just ended as already past', (
    tester,
  ) async {
    final ending = SignupSlot(
      id: 'ending',
      labelEn: 'Ending Now',
      labelMr: '',
      startAt: now.subtract(const Duration(hours: 1)),
      endAt: now.subtract(const Duration(seconds: 1)),
      timezone: 'America/Los_Angeles',
      capacity: 1,
      claimedCount: 0,
      sortOrder: 0,
      createdAt: now,
    );
    await openDialog(tester, [ending], onResult: (_) {});

    expect(find.text('Ending Now'), findsNothing);
  });

  testWidgets('shows slot titles in the language of the app content', (
    tester,
  ) async {
    final marathi = slot(
      'mr',
      'Morning Seva',
      start: DateTime.utc(2026, 10, 10, 18),
      labelMr: 'सकाळची सेवा',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('mr'),
        home: EnglishOnly(
          builder: (context) => Scaffold(
            body: ExportSlotsDialog(slots: [marathi], now: now),
          ),
        ),
      ),
    );

    expect(find.text('सकाळची सेवा'), findsOneWidget);
    expect(find.text('Morning Seva'), findsNothing);
    // The dialog's own words stay English.
    expect(find.text('Export Sign Ups'), findsOneWidget);
  });

  testWidgets('fits a 320px screen at large text, scrolling a long list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final many = [
      for (var i = 0; i < 30; i++)
        slot(
          'slot$i',
          'A rather long slot title number $i',
          start: DateTime.utc(2026, 10, 10).add(Duration(days: i)),
        ),
    ];
    List<SignupSlot>? result;
    await openDialog(tester, many, onResult: (r) => result = r);

    expect(tester.takeException(), isNull);
    expect(exportButton(), findsOneWidget);

    await tester.tap(exportButton());
    await tester.pumpAndSettle();
    expect(result, hasLength(30));
  });
}

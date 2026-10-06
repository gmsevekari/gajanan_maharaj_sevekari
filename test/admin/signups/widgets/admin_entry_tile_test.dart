import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_entry_tile.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';

void main() {
  SignupEntry entry({
    String? phone,
    String? email,
    double? pledgeAmount,
    String? note,
  }) => SignupEntry(
    id: 'e1',
    slotId: 's1',
    name: 'Jane Doe',
    phone: phone,
    email: email,
    pledgeAmount: pledgeAmount,
    note: note,
    joinedAt: DateTime.utc(2026),
  );

  Future<void> show(WidgetTester tester, SignupEntry e) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: AdminEntryTile(entry: e, onEdit: () {}, onRemove: () {}),
        ),
      ),
    ),
  );

  testWidgets('labels the pledge amount, without a trailing .0', (
    tester,
  ) async {
    await show(tester, entry(pledgeAmount: 50));

    expect(find.text('Pledge Amount: 50'), findsOneWidget);
    expect(find.text('50.0'), findsNothing);
  });

  testWidgets('keeps a fractional pledge as it is, and shows a pledge of 0', (
    tester,
  ) async {
    await show(tester, entry(pledgeAmount: 50.5));
    expect(find.text('Pledge Amount: 50.5'), findsOneWidget);

    await show(tester, entry(pledgeAmount: 0));
    expect(find.text('Pledge Amount: 0'), findsOneWidget);
  });

  testWidgets('labels the note', (tester) async {
    await show(tester, entry(note: 'Bringing sweet dish'));

    expect(find.text('Note: Bringing sweet dish'), findsOneWidget);
  });

  testWidgets('shows neither when there is no pledge, and no note or a blank '
      'one', (tester) async {
    await show(tester, entry());
    expect(find.textContaining('Pledge Amount'), findsNothing);
    expect(find.textContaining('Note'), findsNothing);

    await show(tester, entry(note: ''));
    expect(find.textContaining('Note'), findsNothing);
  });

  testWidgets('shows the whole note, not a shortened one', (tester) async {
    final long = List.filled(60, 'sweet').join(' ');
    await show(tester, entry(note: long));

    final text = tester.widget<Text>(find.text('Note: $long'));
    expect(text.maxLines, isNull);
  });

  testWidgets('still shows the phone and email with the contact actions', (
    tester,
  ) async {
    await show(
      tester,
      entry(
        phone: '14255551234',
        email: 'jane@example.com',
        pledgeAmount: 50,
        note: 'Sweets',
      ),
    );

    expect(find.text('14255551234'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(find.byTooltip('WhatsApp'), findsOneWidget);
  });

  testWidgets('lists the pledge before the note, below the contact details', (
    tester,
  ) async {
    await show(
      tester,
      entry(email: 'jane@example.com', pledgeAmount: 50, note: 'Sweets'),
    );

    final email = tester.getRect(find.text('jane@example.com'));
    final pledge = tester.getRect(find.text('Pledge Amount: 50'));
    final note = tester.getRect(find.text('Note: Sweets'));
    expect(pledge.top, greaterThan(email.bottom - 1));
    expect(note.top, greaterThan(pledge.bottom - 1));
  });

  testWidgets('fits a 360px screen at large text with a long note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await show(
      tester,
      entry(
        phone: '14255551234',
        email: 'jane.elizabeth.kulkarni@example.com',
        pledgeAmount: 1000000,
        note: 'y ' * 150,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

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
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    expect(find.text('Jane'), findsOneWidget);
    expect(find.text('Week 1'), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
    expect(find.text('Week 2'), findsOneWidget);
    expect(find.text('Cancel'), findsNWidgets(2));
  });

  testWidgets('hides the Cancel button when showCancelButton is false', (
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
          onCancelEntry: (_) {},
          emptyMessage: 'Nothing here yet',
          showCancelButton: false,
        ),
      ),
    );

    expect(find.text('Jane'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
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
          emptyMessage: 'Nothing here yet',
        ),
      ),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(cancelled, equals(entry));
  });
}

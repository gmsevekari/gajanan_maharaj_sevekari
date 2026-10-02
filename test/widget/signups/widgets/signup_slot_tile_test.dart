import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_slot_tile.dart';

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
    String labelEn = 'Week 1',
    String labelMr = 'आठवडा १',
    DateTime? date,
    int capacity = 3,
    int claimedCount = 0,
  }) {
    return SignupSlot(
      id: 'slot_1',
      labelEn: labelEn,
      labelMr: labelMr,
      date: date,
      capacity: capacity,
      claimedCount: claimedCount,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );
  }

  SignupEntry buildEntry(String name) {
    return SignupEntry(
      id: name,
      slotId: 'slot_1',
      name: name,
      joinedAt: DateTime.now(),
    );
  }

  testWidgets('renders the label and fill count', (tester) async {
    await tester.pumpWidget(
      wrap(
        SignupSlotTile(
          slot: buildSlot(claimedCount: 1),
          entries: const [],
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Week 1'), findsOneWidget);
    expect(find.text('1 of 3 claimed'), findsOneWidget);
  });

  testWidgets('shows the slot date when set', (tester) async {
    await tester.pumpWidget(
      wrap(
        SignupSlotTile(
          slot: buildSlot(date: DateTime(2026, 3, 15)),
          entries: const [],
          onTap: () {},
        ),
      ),
    );

    expect(find.text('March 15'), findsOneWidget);
  });

  testWidgets('shows nothing for the date when unset', (tester) async {
    await tester.pumpWidget(
      wrap(SignupSlotTile(slot: buildSlot(), entries: const [], onTap: () {})),
    );

    expect(find.byIcon(Icons.calendar_today), findsNothing);
  });

  testWidgets('invokes onTap when the Sign Up button is tapped', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        SignupSlotTile(
          slot: buildSlot(),
          entries: const [],
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('shows a Full badge and no Sign Up button when full', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SignupSlotTile(
          slot: buildSlot(capacity: 1, claimedCount: 1),
          entries: const [],
          onTap: null,
        ),
      ),
    );

    expect(find.text('Full'), findsOneWidget);
    expect(find.byKey(const Key('signUpButton')), findsNothing);
  });

  testWidgets('falls back to the Marathi label when English is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SignupSlotTile(
          slot: buildSlot(labelEn: '', labelMr: 'आठवडा १'),
          entries: const [],
          onTap: () {},
        ),
      ),
    );

    expect(find.text('आठवडा १'), findsOneWidget);
  });

  testWidgets('shows a message when no one has signed up yet', (tester) async {
    await tester.pumpWidget(
      wrap(SignupSlotTile(slot: buildSlot(), entries: const [], onTap: () {})),
    );

    expect(
      find.text('No devotees have signed up for this slot yet'),
      findsOneWidget,
    );
  });

  testWidgets('lists the names of devotees already signed up', (tester) async {
    await tester.pumpWidget(
      wrap(
        SignupSlotTile(
          slot: buildSlot(claimedCount: 2),
          entries: [buildEntry('Jane'), buildEntry('John')],
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Jane'), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
    expect(
      find.text('No devotees have signed up for this slot yet'),
      findsNothing,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_slot_tile.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  SignupSlot buildSlot({
    String labelEn = 'Week 1',
    String labelMr = 'आठवडा १',
    int capacity = 3,
    int claimedCount = 0,
  }) {
    return SignupSlot(
      id: 'slot_1',
      labelEn: labelEn,
      labelMr: labelMr,
      capacity: capacity,
      claimedCount: claimedCount,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );
  }

  testWidgets('renders the label and fill count', (tester) async {
    await tester.pumpWidget(
      wrap(SignupSlotTile(slot: buildSlot(claimedCount: 1), onTap: () {})),
    );

    expect(find.text('Week 1'), findsOneWidget);
    expect(find.text('1 of 3 claimed'), findsOneWidget);
  });

  testWidgets('invokes onTap when open and tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(SignupSlotTile(slot: buildSlot(), onTap: () => tapped = true)),
    );

    await tester.tap(find.text('Week 1'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('shows a Full badge and disables the tile when full', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        SignupSlotTile(
          slot: buildSlot(capacity: 1, claimedCount: 1),
          onTap: null,
        ),
      ),
    );

    expect(find.text('Full'), findsOneWidget);

    await tester.tap(find.text('Week 1'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tapped, isFalse);
  });

  testWidgets('falls back to the Marathi label when English is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SignupSlotTile(
          slot: buildSlot(labelEn: '', labelMr: 'आठवडा १'),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('आठवडा १'), findsOneWidget);
  });
}

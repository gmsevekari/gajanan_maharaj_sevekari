import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/my_signups_section.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('shows the empty state when there are no entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(MySignupsSection(entries: const [], onCancelEntry: (_) {})),
    );

    expect(find.text("You haven't signed up for anything yet"), findsOneWidget);
  });

  testWidgets('renders each entry with a Cancel button', (tester) async {
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

    await tester.pumpWidget(
      wrap(MySignupsSection(entries: entries, onCancelEntry: (_) {})),
    );

    expect(find.text('Jane'), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
    expect(find.text('Cancel'), findsNWidgets(2));
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
        MySignupsSection(entries: [entry], onCancelEntry: (e) => cancelled = e),
      ),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(cancelled, equals(entry));
  });
}

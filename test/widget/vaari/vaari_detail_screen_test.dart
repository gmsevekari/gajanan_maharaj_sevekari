import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/vaari/vaari_detail_screen.dart';

void main() {
  Widget createDetailScreen({String? eventId, Locale? locale}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale ?? const Locale('en'),
      home: VaariDetailScreen(eventId: eventId ?? 'vaari_1'),
    );
  }

  group('VaariDetailScreen Widget Tests', () {
    testWidgets('renders localized title and event id in English', (
      tester,
    ) async {
      await tester.pumpWidget(createDetailScreen(eventId: 'vaari_1'));
      await tester.pumpAndSettle();

      expect(find.text('Vaari'), findsOneWidget);
      expect(
        find.text('Details for event vaari_1 coming soon.'),
        findsOneWidget,
      );
    });

    testWidgets('renders localized title and event id in Marathi', (
      tester,
    ) async {
      await tester.pumpWidget(
        createDetailScreen(eventId: 'vaari_2', locale: const Locale('mr')),
      );
      await tester.pumpAndSettle();

      expect(find.text('वारी'), findsOneWidget);
      expect(
        find.text('इव्हेंट vaari_2 चा तपशील लवकरच उपलब्ध होईल.'),
        findsOneWidget,
      );
    });
  });
}

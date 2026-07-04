import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/vaari/widgets/vaari_route_progress.dart';

void main() {
  Widget createWidget({
    required double totalDistance,
    required String distanceUnit,
    Locale? locale,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale ?? const Locale('en'),
      home: Scaffold(
        body: VaariRouteProgress(
          totalDistance: totalDistance,
          distanceUnit: distanceUnit,
        ),
      ),
    );
  }

  group('VaariRouteProgress Widget Tests', () {
    testWidgets('renders the section label and every stop name', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 0, distanceUnit: 'mi'),
      );
      await tester.pumpAndSettle();

      expect(find.text('ROUTE PROGRESS'), findsOneWidget);
      expect(find.text('Alandi'), findsOneWidget);
      expect(find.text('Pandharpur'), findsOneWidget);
    });

    testWidgets('shows covered / total distance in the event unit', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 43.6, distanceUnit: 'mi'),
      );
      await tester.pumpAndSettle();

      expect(find.text('43.6 / 155.0 miles'), findsOneWidget);
    });

    testWidgets(
      'converts km totals into miles for progress and back for display',
      (tester) async {
        // 100 km ≈ 62.1 miles of the 155-mile route.
        await tester.pumpWidget(
          createWidget(totalDistance: 100.0, distanceUnit: 'km'),
        );
        await tester.pumpAndSettle();

        // 155.0 miles ≈ 249.4 km.
        expect(find.text('100.0 / 249.4 km'), findsOneWidget);
      },
    );

    testWidgets('shows the completion message once the full route is covered', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 200.0, distanceUnit: 'mi'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Journey Complete!'), findsOneWidget);
      expect(find.byIcon(Icons.celebration), findsOneWidget);
      expect(find.textContaining(' / '), findsNothing);
    });

    testWidgets('places the walker exactly on the flag once the route is fully '
        'covered (regression: the flag marker used to render shifted away '
        'from its true grid position, so the walker and flag did not '
        'visually coincide at the destination)', (tester) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 200.0, distanceUnit: 'mi'),
      );
      await tester.pumpAndSettle();

      final walkerCenter = tester.getCenter(find.byIcon(Icons.directions_walk));
      final flagCenter = tester.getCenter(find.byIcon(Icons.flag));

      expect(walkerCenter.dx, closeTo(flagCenter.dx, 1.0));
      expect(walkerCenter.dy, closeTo(flagCenter.dy, 1.0));
    });

    testWidgets('clamps negative-looking progress to the start of the route', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 0, distanceUnit: 'mi'),
      );
      await tester.pumpAndSettle();

      expect(find.text('0.0 / 155.0 miles'), findsOneWidget);
    });

    testWidgets('animates the walker to a new position when distance updates', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 0, distanceUnit: 'mi'),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        createWidget(totalDistance: 100.0, distanceUnit: 'mi'),
      );
      // Mid-animation frame: should not have jumped instantly.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('100.0 / 155.0 miles'), findsOneWidget);
    });

    testWidgets('updates the displayed distance when only the unit changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 100.0, distanceUnit: 'mi'),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        createWidget(totalDistance: 100.0, distanceUnit: 'km'),
      );
      await tester.pumpAndSettle();

      expect(find.text('100.0 / 249.4 km'), findsOneWidget);
    });

    testWidgets('shows a flag marker at the final stop', (tester) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 0, distanceUnit: 'mi'),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('renders localized labels and numerals in Marathi', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(
          totalDistance: 43.6,
          distanceUnit: 'mi',
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('मार्गातील प्रगती'), findsOneWidget);
      expect(find.text('४३.६ / १५५.० मैल'), findsOneWidget);
    });
  });
}

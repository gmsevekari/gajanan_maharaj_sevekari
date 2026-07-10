import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/vaari/widgets/vaari_route_progress.dart';

void main() {
  Widget createWidget({
    required double totalDistance,
    required String distanceUnit,
    Locale? locale,
    bool showCard = true,
    double? maxWidth,
    DateTime? todayIst,
  }) {
    final routeProgress = VaariRouteProgress(
      totalDistance: totalDistance,
      distanceUnit: distanceUnit,
      showCard: showCard,
      todayIst: todayIst,
    );
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale ?? const Locale('en'),
      home: Scaffold(
        body: maxWidth == null
            ? routeProgress
            : SizedBox(width: maxWidth, child: routeProgress),
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

    testWidgets(
      'shows the completion message exactly at the end of the route',
      (tester) async {
        await tester.pumpWidget(
          createWidget(totalDistance: 155.0, distanceUnit: 'mi'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Vaari 1 Complete!'), findsOneWidget);
        expect(find.byIcon(Icons.celebration), findsOneWidget);
        expect(find.textContaining(' / '), findsNothing);
      },
    );

    testWidgets('places the walker exactly on the flag once the route is fully '
        'covered (regression: the flag marker used to render shifted away '
        'from its true grid position, so the walker and flag did not '
        'visually coincide at the destination)', (tester) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 155.0, distanceUnit: 'mi'),
      );
      await tester.pumpAndSettle();

      final walkerCenter = tester.getCenter(
        find.byKey(const Key('vaari-group-walker')),
      );
      final flagCenter = tester.getCenter(find.byIcon(Icons.flag));

      expect(walkerCenter.dx, closeTo(flagCenter.dx, 1.0));
      expect(walkerCenter.dy, closeTo(flagCenter.dy, 1.0));
    });

    testWidgets(
      'starts a second lap from Alandi once the group exceeds the total '
      'route distance, instead of stopping at the destination',
      (tester) async {
        await tester.pumpWidget(
          createWidget(totalDistance: 200.0, distanceUnit: 'mi'),
        );
        await tester.pumpAndSettle();

        // 200 - 155 = 45 miles into the second lap.
        expect(find.text('ROUTE PROGRESS • Vaari 2'), findsOneWidget);
        expect(find.text('45.0 / 155.0 miles'), findsOneWidget);
        expect(find.text('Vaari 1 Complete!'), findsNothing);

        // The walker should be partway through the route again, not
        // sitting on the flag at Pandharpur.
        final walkerCenter = tester.getCenter(
          find.byKey(const Key('vaari-group-walker')),
        );
        final flagCenter = tester.getCenter(find.byIcon(Icons.flag));
        expect(walkerCenter.dx, isNot(closeTo(flagCenter.dx, 1.0)));
      },
    );

    testWidgets(
      'shows the lap-complete message with the correct lap number for a '
      'later lap',
      (tester) async {
        await tester.pumpWidget(
          createWidget(totalDistance: 310.0, distanceUnit: 'mi'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Vaari 2 Complete!'), findsOneWidget);
      },
    );

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

    testWidgets('wraps itself in a Card by default', (tester) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 0, distanceUnit: 'mi'),
      );
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.text('ROUTE PROGRESS'),
          matching: find.byType(Card),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders without its own Card when showCard is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 0, distanceUnit: 'mi', showCard: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('ROUTE PROGRESS'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('ROUTE PROGRESS'),
          matching: find.byType(Card),
        ),
        findsNothing,
      );
    });

    testWidgets('does not overlap adjacent stop labels on a narrow layout '
        '(regression: a fixed label width wider than the computed stop '
        'spacing caused names like Velapur/Bhandishegaon to run together '
        'in the narrower admin export card)', (tester) async {
      // Matches the export card's inner width (380 card - 24*2 padding)
      // and showCard:false, exactly as VaariExportCard embeds this widget.
      await tester.pumpWidget(
        createWidget(
          totalDistance: 0,
          distanceUnit: 'mi',
          showCard: false,
          maxWidth: 332,
        ),
      );
      await tester.pumpAndSettle();

      final velapurRect = tester.getRect(find.text('Velapur'));
      final bhandishegaonRect = tester.getRect(find.text('Bhandishegaon'));

      expect(velapurRect.right, lessThanOrEqualTo(bhandishegaonRect.left));
    });

    testWidgets('renders the group/actual-Palkhi legend', (tester) async {
      await tester.pumpWidget(
        createWidget(totalDistance: 0, distanceUnit: 'mi'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Group'), findsOneWidget);
      expect(find.text('Actual Palkhi Today'), findsOneWidget);
    });

    testWidgets(
      'places the actual-Palkhi marker at Alandi before the schedule starts',
      (tester) async {
        await tester.pumpWidget(
          createWidget(
            totalDistance: 0,
            distanceUnit: 'mi',
            todayIst: DateTime(2026, 1, 1),
          ),
        );
        await tester.pumpAndSettle();

        final scheduleCenter = tester.getCenter(
          find.byKey(const Key('vaari-schedule-walker')),
        );
        final alandiCenter = tester.getCenter(find.text('Alandi'));

        expect(scheduleCenter.dx, closeTo(alandiCenter.dx, 1.0));
      },
    );

    testWidgets(
      'places the actual-Palkhi marker at the stop scheduled for today',
      (tester) async {
        await tester.pumpWidget(
          createWidget(
            totalDistance: 0,
            distanceUnit: 'mi',
            // Jejuri is scheduled for July 13, 2026.
            todayIst: DateTime(2026, 7, 13),
          ),
        );
        await tester.pumpAndSettle();

        final scheduleCenter = tester.getCenter(
          find.byKey(const Key('vaari-schedule-walker')),
        );
        final jejuriCenter = tester.getCenter(find.text('Jejuri'));

        expect(scheduleCenter.dx, closeTo(jejuriCenter.dx, 1.0));
      },
    );

    testWidgets(
      'places the actual-Palkhi marker at Pandharpur once the schedule ends',
      (tester) async {
        await tester.pumpWidget(
          createWidget(
            totalDistance: 0,
            distanceUnit: 'mi',
            todayIst: DateTime(2027, 1, 1),
          ),
        );
        await tester.pumpAndSettle();

        final scheduleCenter = tester.getCenter(
          find.byKey(const Key('vaari-schedule-walker')),
        );
        final flagCenter = tester.getCenter(find.byIcon(Icons.flag));

        expect(scheduleCenter.dx, closeTo(flagCenter.dx, 1.0));
      },
    );
  });
}

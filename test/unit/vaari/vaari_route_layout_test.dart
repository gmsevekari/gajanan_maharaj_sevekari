import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/vaari/vaari_route_layout.dart';

void main() {
  group('VaariRouteLayout', () {
    test('fits at least 2 stops per row even on a very narrow width', () {
      final layout = VaariRouteLayout(availableWidth: 50, stopCount: 6);
      expect(layout.stopsPerRow, greaterThanOrEqualTo(2));
    });

    test('computes more stops per row on a wider layout', () {
      final narrow = VaariRouteLayout(availableWidth: 250, stopCount: 15);
      final wide = VaariRouteLayout(availableWidth: 500, stopCount: 15);
      expect(wide.stopsPerRow, greaterThan(narrow.stopsPerRow));
    });

    test('fits the default target of 5 stops per row when width allows', () {
      final layout = VaariRouteLayout(availableWidth: 360, stopCount: 15);
      expect(layout.stopsPerRow, 5);
    });

    test('falls back to fewer stops per row when 5 would be too cramped', () {
      final layout = VaariRouteLayout(availableWidth: 200, stopCount: 15);
      expect(layout.stopsPerRow, lessThan(5));
      expect(layout.stopSpacing, greaterThanOrEqualTo(0));
    });

    test('never produces negative spacing on an unreasonably narrow width', () {
      final layout = VaariRouteLayout(availableWidth: 10, stopCount: 6);
      expect(layout.stopSpacing, greaterThanOrEqualTo(0));
    });

    test('lays out stops in a boustrophedon (snake) pattern', () {
      // 3 per row forces: row0 L->R, row1 R->L, row2 L->R for 9 stops.
      final layout = VaariRouteLayout(
        availableWidth: 300,
        stopCount: 9,
        stopSpacingOverride: 80,
      );
      expect(layout.stopsPerRow, 3);

      // Row 0 (indices 0,1,2): x increases left to right.
      expect(layout.stopPositions[0].dx, lessThan(layout.stopPositions[1].dx));
      expect(layout.stopPositions[1].dx, lessThan(layout.stopPositions[2].dx));

      // Row 1 (indices 3,4,5): x decreases (wraps right-to-left), and stop 3
      // shares its x with stop 2 (both at the row's right edge).
      expect(
        layout.stopPositions[3].dx,
        closeTo(layout.stopPositions[2].dx, 0.01),
      );
      expect(
        layout.stopPositions[3].dx,
        greaterThan(layout.stopPositions[4].dx),
      );
      expect(
        layout.stopPositions[4].dx,
        greaterThan(layout.stopPositions[5].dx),
      );

      // Row 2 (indices 6,7,8): x increases again, and stop 6 shares its x
      // with stop 5 (both at the row's left edge).
      expect(
        layout.stopPositions[6].dx,
        closeTo(layout.stopPositions[5].dx, 0.01),
      );
      expect(layout.stopPositions[6].dx, lessThan(layout.stopPositions[7].dx));
    });

    test('rows are separated vertically by rowHeight', () {
      final layout = VaariRouteLayout(
        availableWidth: 300,
        stopCount: 9,
        stopSpacingOverride: 80,
        rowHeight: 80,
      );
      expect(
        layout.stopPositions[3].dy - layout.stopPositions[0].dy,
        closeTo(80, 0.01),
      );
      expect(
        layout.stopPositions[6].dy - layout.stopPositions[3].dy,
        closeTo(80, 0.01),
      );
    });

    test('total arc length sums straight segments and semicircle turns', () {
      final layout = VaariRouteLayout(
        availableWidth: 300,
        stopCount: 9,
        stopSpacingOverride: 80,
        rowHeight: 80,
      );
      // 9 stops -> 8 legs; with 3 per row that's 2 wrap turns and 6 straight
      // segments (2 per row * 3 rows = 6 straight legs within rows).
      final expectedLength = 6 * 80 + 2 * (math.pi * layout.turnRadius);
      expect(layout.totalArcLength, closeTo(expectedLength, 0.01));
    });

    test('arcLengthForMiles(0) returns 0', () {
      final layout = VaariRouteLayout(availableWidth: 300, stopCount: 9);
      expect(layout.arcLengthForMiles(0), 0.0);
    });

    test(
      'arcLengthForMiles at the final stop returns the total arc length',
      () {
        final layout = VaariRouteLayout(availableWidth: 300);
        final totalMiles = layout.arcLengthForMiles(9999);
        expect(totalMiles, closeTo(layout.totalArcLength, 0.01));
      },
    );

    test('positionAtArcLength(0) matches the first stop position', () {
      final layout = VaariRouteLayout(availableWidth: 300);
      final pos = layout.positionAtArcLength(0);
      expect(pos.dx, closeTo(layout.stopPositions.first.dx, 0.5));
      expect(pos.dy, closeTo(layout.stopPositions.first.dy, 0.5));
    });

    test(
      'positionAtArcLength(totalArcLength) matches the last stop position',
      () {
        final layout = VaariRouteLayout(availableWidth: 300);
        final pos = layout.positionAtArcLength(layout.totalArcLength);
        expect(pos.dx, closeTo(layout.stopPositions.last.dx, 0.5));
        expect(pos.dy, closeTo(layout.stopPositions.last.dy, 0.5));
      },
    );

    test('extractCoveredPath(0) yields an empty path', () {
      final layout = VaariRouteLayout(availableWidth: 300);
      final covered = layout.extractCoveredPath(0);
      expect(covered.computeMetrics().isEmpty, isTrue);
    });

    test(
      'extractCoveredPath(totalArcLength) yields a path of the same length',
      () {
        final layout = VaariRouteLayout(availableWidth: 300);
        final covered = layout.extractCoveredPath(layout.totalArcLength);
        final coveredLength = covered.computeMetrics().first.length;
        // Skia approximates curves with line segments, so tolerate its
        // tessellation slop rather than requiring exact equality.
        expect(coveredLength, closeTo(layout.totalArcLength, 2.0));
      },
    );

    test('a partial trailing row still enters at the same column the previous '
        'row exited from, so the connecting U-turn stays a vertical semicircle '
        '(regression: previously the walker fell short of the last stop)', () {
      // 13 stops at 5 per row -> rows of 5, 5, 3: the last row is partial.
      final layout = VaariRouteLayout(availableWidth: 360, stopCount: 13);
      expect(layout.stopsPerRow, 5);
      expect(layout.rowCount, 3);

      // Row 1 (indices 5-9) exits at index 9; row 2 (indices 10-12) enters
      // at index 10. Both must land on the same column (x) for the
      // connecting arcToPoint to be a true vertical semicircle.
      expect(
        layout.stopPositions[10].dx,
        closeTo(layout.stopPositions[9].dx, 0.01),
      );

      // With the alignment fixed, the recorded arc length for the full
      // route must match the path's actual rendered length, so the walker
      // (placed via positionAtArcLength) lands exactly on the last stop.
      final endOfPath = layout.positionAtArcLength(layout.totalArcLength);
      expect(endOfPath.dx, closeTo(layout.stopPositions.last.dx, 0.5));
      expect(endOfPath.dy, closeTo(layout.stopPositions.last.dy, 0.5));
    });

    test('clamps arc lengths outside the valid range', () {
      final layout = VaariRouteLayout(availableWidth: 300);
      expect(layout.positionAtArcLength(-50), layout.positionAtArcLength(0));
      expect(
        layout.positionAtArcLength(layout.totalArcLength + 500),
        layout.positionAtArcLength(layout.totalArcLength),
      );
    });
  });
}

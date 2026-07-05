import 'dart:math' as math;
import 'dart:ui';

import 'package:gajanan_maharaj_sevekari/vaari/vaari_route.dart';

/// Lays [dnyaneshwarPalkhiRoute]'s stops out as a "snake"/boustrophedon path
/// that wraps into multiple rows to fit [availableWidth], connecting rows
/// with a rounded U-turn instead of requiring horizontal scrolling.
///
/// Row 0 runs left-to-right, row 1 right-to-left, row 2 left-to-right, and
/// so on — alternating so consecutive stops are always adjacent on screen.
class VaariRouteLayout {
  late final double stopSpacing;
  final double rowHeight;
  final int stopCount;
  final int targetStopsPerRow;
  final double minStopSpacing;

  late final int stopsPerRow;
  late final int rowCount;
  late final double turnRadius;
  late final double sidePadding;

  /// Grid position (center) of each stop, in local coordinates.
  late final List<Offset> stopPositions;

  /// The full snake path connecting every stop in order.
  late final Path path;

  /// Arc length from the path's start to each stop, same length/order as
  /// [stopPositions].
  late final List<double> cumulativeArcLength;

  late final double totalArcLength;
  late final double contentWidth;
  late final double contentHeight;

  late final PathMetric _pathMetric;

  /// [stopSpacingOverride], when provided, fixes the spacing between stops
  /// exactly (used by tests that need predictable geometry). Otherwise the
  /// spacing is derived from [availableWidth] to fit [targetStopsPerRow]
  /// stops per row, falling back to fewer per row only if that would make
  /// [minStopSpacing] too cramped to read.
  VaariRouteLayout({
    required double availableWidth,
    int? stopCount,
    double? stopSpacingOverride,
    this.rowHeight = 80,
    this.targetStopsPerRow = 5,
    this.minStopSpacing = 56,
  }) : stopCount = stopCount ?? dnyaneshwarPalkhiRoute.length {
    if (this.stopCount < 2) {
      throw ArgumentError(
        'VaariRouteLayout requires at least 2 stops to compute spacing and render segments.',
      );
    }
    turnRadius = rowHeight / 2;
    sidePadding = turnRadius + 12;
    _resolveSpacing(availableWidth, stopSpacingOverride);
    rowCount = (this.stopCount / stopsPerRow).ceil();
    _build(availableWidth);
  }

  void _resolveSpacing(double availableWidth, double? stopSpacingOverride) {
    final usableWidth = math.max(0.0, availableWidth - 2 * sidePadding);
    if (stopSpacingOverride != null) {
      stopSpacing = stopSpacingOverride;
      final fitted = (usableWidth / stopSpacing).floor() + 1;
      stopsPerRow = fitted.clamp(2, stopCount);
      return;
    }

    final idealSpacing = targetStopsPerRow > 1
        ? usableWidth / (targetStopsPerRow - 1)
        : usableWidth;
    if (idealSpacing >= minStopSpacing) {
      stopsPerRow = targetStopsPerRow.clamp(2, stopCount);
    } else {
      final fitted = (usableWidth / minStopSpacing).floor() + 1;
      stopsPerRow = fitted.clamp(2, stopCount);
    }
    stopSpacing = stopsPerRow > 1
        ? usableWidth / (stopsPerRow - 1)
        : usableWidth;
  }

  void _build(double availableWidth) {
    stopPositions = List.generate(stopCount, (i) {
      final row = i ~/ stopsPerRow;
      final indexInRow = i % stopsPerRow;
      // Always measure columns against the full `stopsPerRow` grid (not how
      // many stops actually land in this row) so a partial trailing row
      // still enters at the same column the previous row exited from —
      // otherwise the U-turn connecting them isn't a vertical semicircle.
      final col = row.isEven ? indexInRow : (stopsPerRow - 1 - indexInRow);
      final x = sidePadding + col * stopSpacing;
      final y = turnRadius + row * rowHeight;
      return Offset(x, y);
    });

    path = Path()..moveTo(stopPositions[0].dx, stopPositions[0].dy);
    cumulativeArcLength = [0.0];
    double length = 0.0;

    for (var i = 1; i < stopCount; i++) {
      final prevRow = (i - 1) ~/ stopsPerRow;
      final curRow = i ~/ stopsPerRow;
      final point = stopPositions[i];

      if (curRow == prevRow) {
        path.lineTo(point.dx, point.dy);
        length += stopSpacing;
      } else {
        // Wrapping to a new row: both points share the same x (the row's
        // edge column), so a semicircle of radius `turnRadius` connects
        // them with a rounded U-turn that bulges outward past that edge.
        final bulgesRight = prevRow.isEven;
        path.arcToPoint(
          point,
          radius: Radius.circular(turnRadius),
          clockwise: bulgesRight,
        );
        length += math.pi * turnRadius;
      }
      cumulativeArcLength.add(length);
    }

    totalArcLength = length;
    _pathMetric = path.computeMetrics().first;

    contentWidth = math.max(
      availableWidth,
      sidePadding * 2 + (stopsPerRow - 1) * stopSpacing,
    );
    contentHeight = (rowCount - 1) * rowHeight + turnRadius * 2;
  }

  /// The (x, y) position along the snake path at the given fraction of
  /// [totalArcLength], used to draw the "covered so far" highlight and place
  /// the animated walker marker.
  Offset positionAtArcLength(double arcLength) {
    final clamped = arcLength.clamp(0.0, totalArcLength);
    final tangent = _pathMetric.getTangentForOffset(clamped);
    return tangent?.position ?? stopPositions.first;
  }

  /// Extracts the portion of [path] from the start up to [arcLength], for
  /// drawing the "covered so far" highlight.
  Path extractCoveredPath(double arcLength) {
    final clamped = arcLength.clamp(0.0, totalArcLength);
    return _pathMetric.extractPath(0, clamped);
  }

  /// Converts a real-world mileage covered along [dnyaneshwarPalkhiRoute]
  /// into an arc length along this visual layout's path — interpolating
  /// within the current leg so the walker lands at the correct fractional
  /// point between two stops (including smoothly following a U-turn curve
  /// when the current leg happens to wrap to a new row).
  double arcLengthForMiles(double coveredMiles) {
    final stops = dnyaneshwarPalkhiRoute;
    for (var i = 0; i < stops.length - 1; i++) {
      final current = stops[i];
      final next = stops[i + 1];
      final isLastLeg = i == stops.length - 2;
      if (coveredMiles <= next.cumulativeMiles || isLastLeg) {
        final legDistance = next.cumulativeMiles - current.cumulativeMiles;
        final legFraction = legDistance == 0
            ? 0.0
            : ((coveredMiles - current.cumulativeMiles) / legDistance).clamp(
                0.0,
                1.0,
              );
        final arcStart = cumulativeArcLength[i];
        final arcEnd = cumulativeArcLength[i + 1];
        return arcStart + legFraction * (arcEnd - arcStart);
      }
    }
    return 0.0;
  }
}

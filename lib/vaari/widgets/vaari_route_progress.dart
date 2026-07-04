import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/vaari/vaari_route.dart';
import 'package:gajanan_maharaj_sevekari/vaari/vaari_route_layout.dart';

/// Animates the group's collective walking distance along the fixed
/// Alandi -> Pandharpur route ([dnyaneshwarPalkhiRoute]) as a snake-shaped
/// timeline that wraps into multiple rows (connected by rounded U-turns)
/// instead of scrolling off-screen, so participants can see how far "the
/// group" has symbolically traveled along the real pilgrimage.
class VaariRouteProgress extends StatelessWidget {
  final double totalDistance;
  final String distanceUnit;

  const VaariRouteProgress({
    super.key,
    required this.totalDistance,
    required this.distanceUnit,
  });

  double get _totalRouteMiles => dnyaneshwarPalkhiRoute.last.cumulativeMiles;

  double get _coveredMiles {
    final miles = distanceUnitToMiles(totalDistance, distanceUnit);
    return miles.clamp(0.0, _totalRouteMiles);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final covered = _coveredMiles;
    final isComplete = covered >= _totalRouteMiles;
    final unit = localizedDistanceUnitLabel(distanceUnit, locale);
    final coveredDisplay = formatDistanceLocalized(
      milesToDistanceUnit(covered, distanceUnit),
      locale,
    );
    final totalDisplay = formatDistanceLocalized(
      milesToDistanceUnit(_totalRouteMiles, distanceUnit),
      locale,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.vaariRouteProgressLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                if (isComplete)
                  Row(
                    children: [
                      Icon(
                        Icons.celebration,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        localizations.vaariRouteComplete,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '$coveredDisplay / $totalDisplay $unit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final layout = VaariRouteLayout(
                  availableWidth: constraints.maxWidth,
                );
                return SizedBox(
                  width: layout.contentWidth,
                  height: layout.contentHeight,
                  child: _VaariRouteTimeline(layout: layout, covered: covered),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VaariRouteTimeline extends StatelessWidget {
  static const double _markerRadius = 11.0;
  static const double _flagRadius = 14.0;
  static const double _walkerRadius = 16.0;
  static const double _labelGap = 8.0;
  static const double _labelWidth = 78.0;

  final VaariRouteLayout layout;
  final double covered;

  const _VaariRouteTimeline({required this.layout, required this.covered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetArcLength = layout.arcLengthForMiles(covered);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: Size(layout.contentWidth, layout.contentHeight),
          painter: _RoutePathPainter(
            layout: layout,
            trackColor: theme.appColors.divider,
          ),
        ),
        for (var i = 0; i < dnyaneshwarPalkhiRoute.length; i++)
          _buildStopMarker(theme, i),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: targetArcLength),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          builder: (context, animatedArcLength, child) {
            final position = layout.positionAtArcLength(animatedArcLength);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(layout.contentWidth, layout.contentHeight),
                  painter: _RoutePathPainter(
                    layout: layout,
                    trackColor: theme.colorScheme.primary,
                    coveredArcLength: animatedArcLength,
                  ),
                ),
                Positioned(
                  left: position.dx - _walkerRadius,
                  top: position.dy - _walkerRadius,
                  child: child!,
                ),
              ],
            );
          },
          child: CircleAvatar(
            radius: _walkerRadius,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.directions_walk,
              color: theme.colorScheme.onPrimary,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStopMarker(ThemeData theme, int index) {
    final stop = dnyaneshwarPalkhiRoute[index];
    final isPassed = covered >= stop.cumulativeMiles;
    final isDestination = index == dnyaneshwarPalkhiRoute.length - 1;
    final center = layout.stopPositions[index];
    final radius = isDestination ? _flagRadius : _markerRadius;

    // The label is wider than the marker circle, so the whole column must be
    // fixed to _labelWidth and centered on `center.dx` — otherwise Column's
    // default cross-axis centering widens the box to fit the label and
    // re-centers the (narrower) circle within it, silently shifting every
    // marker off its true grid position by a few pixels.
    return Positioned(
      left: center.dx - _labelWidth / 2,
      top: center.dy - radius,
      child: SizedBox(
        width: _labelWidth,
        child: Column(
          children: [
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPassed
                    ? theme.colorScheme.primary
                    : theme.appColors.surface,
                border: Border.all(
                  color: isPassed
                      ? theme.colorScheme.primary
                      : theme.appColors.divider,
                  width: 2,
                ),
              ),
              child: isDestination
                  ? Icon(
                      Icons.flag,
                      size: radius,
                      color: isPassed
                          ? theme.colorScheme.onPrimary
                          : theme.appColors.secondaryText,
                    )
                  : null,
            ),
            const SizedBox(height: _labelGap),
            Text(
              stop.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isPassed ? FontWeight.bold : FontWeight.normal,
                color: isPassed
                    ? theme.colorScheme.primary
                    : theme.appColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the snake-shaped route path, either in full (the background
/// track) or truncated to [coveredArcLength] (the "covered so far"
/// highlight).
class _RoutePathPainter extends CustomPainter {
  final VaariRouteLayout layout;
  final Color trackColor;
  final double? coveredArcLength;

  const _RoutePathPainter({
    required this.layout,
    required this.trackColor,
    this.coveredArcLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = coveredArcLength == null
        ? layout.path
        : layout.extractCoveredPath(coveredArcLength!);

    final paint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePathPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.coveredArcLength != coveredArcLength;
  }
}

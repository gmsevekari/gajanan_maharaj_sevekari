import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/vaari/vaari_route.dart';
import 'package:gajanan_maharaj_sevekari/vaari/vaari_route_layout.dart';
import 'package:gajanan_maharaj_sevekari/vaari/vaari_schedule.dart';

/// Animates the group's collective walking distance along the fixed
/// Alandi -> Pandharpur route ([dnyaneshwarPalkhiRoute]) as a snake-shaped
/// timeline that wraps into multiple rows (connected by rounded U-turns)
/// instead of scrolling off-screen, so participants can see how far "the
/// group" has symbolically traveled along the real pilgrimage.
class VaariRouteProgress extends StatelessWidget {
  final double totalDistance;
  final String distanceUnit;

  /// When false, renders the label and timeline directly without the
  /// surrounding [Card] — for embedding inside a container (e.g. the admin
  /// export card) that already provides its own card-like chrome.
  final bool showCard;

  /// Today's date in India Standard Time, used to place the green "actual
  /// Palkhi" marker. Defaults to [currentIstDate]; overridable for testing.
  final DateTime? todayIst;

  const VaariRouteProgress({
    super.key,
    required this.totalDistance,
    required this.distanceUnit,
    this.showCard = true,
    this.todayIst,
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
    final scheduledStopIndex = scheduledStopIndexForDate(
      todayIst ?? currentIstDate(),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                localizations.vaariRouteProgressLabel,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: isComplete
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.celebration,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            localizations.vaariRouteComplete,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '$coveredDisplay / $totalDisplay $unit',
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _buildLegendItem(
              theme,
              theme.colorScheme.primary,
              localizations.vaariGroupProgressLegend,
            ),
            _buildLegendItem(
              theme,
              theme.appColors.success,
              localizations.vaariActualPalkhiLegend,
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final layout = VaariRouteLayout(
              availableWidth: constraints.maxWidth,
            );
            return SizedBox(
              width: layout.contentWidth,
              height: layout.contentHeight,
              child: _VaariRouteTimeline(
                layout: layout,
                covered: covered,
                scheduledStopIndex: scheduledStopIndex,
              ),
            );
          },
        ),
      ],
    );

    if (!showCard) return content;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16.0), child: content),
    );
  }

  Widget _buildLegendItem(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.appColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _VaariRouteTimeline extends StatelessWidget {
  static const double _markerRadius = 11.0;
  static const double _flagRadius = 14.0;
  static const double _walkerRadius = 16.0;
  static const double _scheduledWalkerRadius = 14.0;
  static const double _labelGap = 8.0;
  static const double _maxLabelWidth = 78.0;

  final VaariRouteLayout layout;
  final double covered;
  final int scheduledStopIndex;

  const _VaariRouteTimeline({
    required this.layout,
    required this.covered,
    required this.scheduledStopIndex,
  });

  /// Capped to the actual gap between stops so adjacent labels never
  /// overlap — on a narrow layout (e.g. the admin export card) stopSpacing
  /// can shrink below the label's natural width.
  double get _labelWidth =>
      layout.stopSpacing < _maxLabelWidth ? layout.stopSpacing : _maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetArcLength = layout.arcLengthForMiles(covered);
    final scheduledStopIndexClamped = scheduledStopIndex.clamp(
      0,
      layout.cumulativeArcLength.length - 1,
    );
    final scheduledArcLength = layout.cumulativeArcLength.isEmpty
        ? 0.0
        : layout.cumulativeArcLength[scheduledStopIndexClamped];

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
        for (var i = 0; i < layout.stopPositions.length; i++)
          _buildStopMarker(context, theme, i),
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
            key: const Key('vaari-group-walker'),
            radius: _walkerRadius,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.directions_walk,
              color: theme.colorScheme.onPrimary,
              size: 18,
            ),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: scheduledArcLength),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          builder: (context, animatedArcLength, child) {
            final position = layout.positionAtArcLength(animatedArcLength);
            return Positioned(
              left: position.dx - _scheduledWalkerRadius,
              top: position.dy - _scheduledWalkerRadius,
              child: child!,
            );
          },
          child: CircleAvatar(
            key: const Key('vaari-schedule-walker'),
            radius: _scheduledWalkerRadius,
            backgroundColor: theme.appColors.success,
            child: Icon(
              Icons.directions_walk,
              color: theme.colorScheme.onPrimary,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStopMarker(BuildContext context, ThemeData theme, int index) {
    if (index >= dnyaneshwarPalkhiRoute.length) {
      return const SizedBox.shrink();
    }
    final stop = dnyaneshwarPalkhiRoute[index];
    final isPassed = covered >= stop.cumulativeMiles;
    final isDestination = index == dnyaneshwarPalkhiRoute.length - 1;
    final center = layout.stopPositions[index];
    final radius = isDestination ? _flagRadius : _markerRadius;
    final locale = Localizations.localeOf(context).languageCode;

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
              stop.localizedName(locale),
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

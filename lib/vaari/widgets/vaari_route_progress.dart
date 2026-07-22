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

  /// Raw cumulative miles the group has walked, unclamped — once this
  /// exceeds the route's total length, the group has completed a lap and
  /// started again from Alandi, so this feeds into [computeLapProgress]
  /// rather than being clamped to a single pass.
  double get _cumulativeMiles =>
      distanceUnitToMiles(totalDistance, distanceUnit);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final lapProgress = computeLapProgress(_cumulativeMiles, _totalRouteMiles);
    final covered = lapProgress.milesInLap;
    final isLapComplete = covered >= _totalRouteMiles;
    final unit = localizedDistanceUnitLabel(distanceUnit, locale);
    final coveredDisplay = formatDistanceLocalized(
      milesToDistanceUnit(covered, distanceUnit),
      locale,
    );
    final totalDisplay = formatDistanceLocalized(
      milesToDistanceUnit(_totalRouteMiles, distanceUnit),
      locale,
    );
    final lapNumberDisplay = formatNumberLocalized(
      lapProgress.lapNumber,
      locale,
      pad: false,
    );
    final scheduledStopIndex = scheduledStopIndexForDate(
      todayIst ?? currentIstDate(),
    );

    // Calculate individual lap miles
    final lap1Miles = _cumulativeMiles.clamp(0.0, _totalRouteMiles);
    final lap2Miles = (_cumulativeMiles - _totalRouteMiles).clamp(
      0.0,
      _totalRouteMiles,
    );
    final lap3Miles = (_cumulativeMiles - 2 * _totalRouteMiles).clamp(
      0.0,
      _totalRouteMiles,
    );

    // Color assignments:
    // - Completed Vaari 1: Royal Blue (high contrast against Saffron)
    // - Completed Vaari 2: Deep Purple
    // - Current Active Vaari: Always Primary Saffron
    const blueColor = Color(0xFF1E88E5); // Royal Blue for Completed Vaari 1
    const purpleColor = Color(0xFF8E24AA); // Deep Purple for Completed Vaari 2
    final primarySaffron = theme.colorScheme.primary; // Current Vaari

    final Color lap1Color;
    final Color lap2Color;
    final Color lap3Color;

    if (lapProgress.lapNumber == 1) {
      lap1Color = primarySaffron;
      lap2Color = primarySaffron;
      lap3Color = primarySaffron;
    } else if (lapProgress.lapNumber == 2) {
      lap1Color = blueColor;
      lap2Color = primarySaffron;
      lap3Color = primarySaffron;
    } else {
      lap1Color = blueColor;
      lap2Color = purpleColor;
      lap3Color = primarySaffron;
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                lapProgress.lapNumber > 1
                    ? '${localizations.vaariRouteProgressLabel} • ${localizations.vaariLapLabel(lapNumberDisplay)}'
                    : localizations.vaariRouteProgressLabel,
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
              child: isLapComplete
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
                            localizations.vaariLapCompleteLabel(
                              lapNumberDisplay,
                            ),
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
            if (lapProgress.lapNumber == 1)
              _buildLegendItem(
                theme,
                primarySaffron,
                localizations.vaariGroupProgressLegend,
              )
            else ...[
              _buildLegendItem(
                theme,
                lap1Color,
                localizations.vaariLapLabel(
                  formatNumberLocalized(1, locale, pad: false),
                ),
              ),
              _buildLegendItem(
                theme,
                lap2Color,
                localizations.vaariLapLabel(
                  formatNumberLocalized(2, locale, pad: false),
                ),
              ),
              if (lapProgress.lapNumber >= 3)
                _buildLegendItem(
                  theme,
                  lap3Color,
                  localizations.vaariLapLabel(
                    formatNumberLocalized(3, locale, pad: false),
                  ),
                ),
            ],
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
                lap1Miles: lap1Miles,
                lap2Miles: lap2Miles,
                lap3Miles: lap3Miles,
                scheduledStopIndex: scheduledStopIndex,
                lap1Color: lap1Color,
                lap2Color: lap2Color,
                lap3Color: lap3Color,
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

class LapTrackLayer {
  final double arcLength;
  final Color color;
  final double strokeWidth;

  const LapTrackLayer({
    required this.arcLength,
    required this.color,
    required this.strokeWidth,
  });
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
  final double lap1Miles;
  final double lap2Miles;
  final double lap3Miles;
  final int scheduledStopIndex;
  final Color lap1Color;
  final Color lap2Color;
  final Color lap3Color;

  const _VaariRouteTimeline({
    required this.layout,
    required this.covered,
    required this.lap1Miles,
    required this.lap2Miles,
    required this.lap3Miles,
    required this.scheduledStopIndex,
    required this.lap1Color,
    required this.lap2Color,
    required this.lap3Color,
  });

  /// Capped to the actual gap between stops so adjacent labels never
  /// overlap — on a narrow layout (e.g. the admin export card) stopSpacing
  /// can shrink below the label's natural width.
  double get _labelWidth =>
      layout.stopSpacing < _maxLabelWidth ? layout.stopSpacing : _maxLabelWidth;

  List<LapTrackLayer> _buildLapLayers(ThemeData theme) {
    final layers = <LapTrackLayer>[];
    if (lap1Miles > 0) {
      layers.add(
        LapTrackLayer(
          arcLength: layout.arcLengthForMiles(lap1Miles),
          color: lap1Color,
          strokeWidth: 18.0,
        ),
      );
    }
    if (lap2Miles > 0) {
      layers.add(
        LapTrackLayer(
          arcLength: layout.arcLengthForMiles(lap2Miles),
          color: lap2Color,
          strokeWidth: 12.0,
        ),
      );
    }
    if (lap3Miles > 0) {
      layers.add(
        LapTrackLayer(
          arcLength: layout.arcLengthForMiles(lap3Miles),
          color: lap3Color,
          strokeWidth: 6.0,
        ),
      );
    }
    return layers;
  }

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

    final lapLayers = _buildLapLayers(theme);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: Size(layout.contentWidth, layout.contentHeight),
          painter: _RoutePathPainter(
            layout: layout,
            baseTrackColor: theme.appColors.divider,
            lapLayers: lapLayers,
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
            return Positioned(
              left: position.dx - _walkerRadius,
              top: position.dy - _walkerRadius,
              child: child!,
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

/// Paints the snake-shaped route path with base track and concentric
/// multi-colored lap layers.
class _RoutePathPainter extends CustomPainter {
  final VaariRouteLayout layout;
  final Color baseTrackColor;
  final List<LapTrackLayer> lapLayers;

  const _RoutePathPainter({
    required this.layout,
    required this.baseTrackColor,
    required this.lapLayers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base route track
    final basePaint = Paint()
      ..color = baseTrackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(layout.path, basePaint);

    // 2. Multi-colored concentric lap tracks
    for (final layer in lapLayers) {
      if (layer.arcLength <= 0) continue;
      final lapPath = layout.extractCoveredPath(layer.arcLength);
      final lapPaint = Paint()
        ..color = layer.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = layer.strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(lapPath, lapPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePathPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.baseTrackColor != baseTrackColor ||
        oldDelegate.lapLayers != lapLayers;
  }
}

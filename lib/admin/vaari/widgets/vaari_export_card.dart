import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

class VaariExportCard extends StatelessWidget {
  /// Fixed width of the exported PNG card, in logical pixels.
  static const double _cardWidth = 380;

  final VaariEvent event;
  final String eventName;
  final String dateRange;
  final int participantCount;
  final String groupName;
  final AppLocalizations l10n;
  final ThemeData theme;
  final String langCode;

  const VaariExportCard({
    super.key,
    required this.event,
    required this.eventName,
    required this.dateRange,
    required this.participantCount,
    required this.groupName,
    required this.l10n,
    required this.theme,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    final displaySteps = formatNumberLocalized(
      event.totalSteps,
      langCode,
      pad: false,
    );
    final totalDistanceStr = formatDistanceLocalized(
      event.totalDistance,
      langCode,
    );
    final targetDistanceStr = formatDistanceLocalized(
      event.targetDistance,
      langCode,
    );
    final displayDistance = '$totalDistanceStr / $targetDistanceStr';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: _cardWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.appColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Row 1: Logo + App Name
            Row(
              children: [
                Image.asset(
                  'resources/images/logo/App_Logo.png',
                  width: 48,
                  height: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    groupName.isNotEmpty
                        ? '${l10n.appName} - $groupName'
                        : l10n.appName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.appColors.primarySwatch,
                    ),
                  ),
                ),
              ],
            ),
            Divider(
              height: 24,
              thickness: 1.5,
              color: theme.appColors.primarySwatch,
            ),

            // Row 2: Event Details
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateRange,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: theme.appColors.divider),
            const SizedBox(height: 16),

            // Row 3: Participant count
            Text(
              l10n.vaariTotalParticipants,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                color: theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatNumberLocalized(participantCount, langCode, pad: false),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Row 4: Total Steps
            Text(
              l10n.adminVaariTotalSteps,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                color: theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displaySteps,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Row 5: Total Distance
            Text(
              l10n.adminVaariTotalDistance,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                color: theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$displayDistance ${localizedDistanceUnitLabel(event.distanceUnit, langCode)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

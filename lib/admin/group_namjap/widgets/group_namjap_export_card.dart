import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

class GroupNamjapExportCard extends StatelessWidget {
  final GroupNamjapEvent event;
  final String eventName;
  final String sankalp;
  final String dateRange;
  final String percentStr;
  final double progress;
  final int participantCount;
  final AppLocalizations l10n;
  final ThemeData theme;
  final String langCode;

  const GroupNamjapExportCard({
    super.key,
    required this.event,
    required this.eventName,
    required this.sankalp,
    required this.dateRange,
    required this.percentStr,
    required this.progress,
    required this.participantCount,
    required this.l10n,
    required this.theme,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
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
                    l10n.appName,
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

            // Row 2: Namjap Details
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
                    sankalp,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.appColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.groupNamjapMantra}: ${event.mantra}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.appColors.secondaryText,
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
              l10n.groupNamjapTotalParticipants,
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

            // Row 4: Current count
            Text(
              l10n.groupNamjapAchievedLabel,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                color: theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatNumberLocalized(event.totalCount, langCode, pad: false)} / ${formatNumberLocalized(event.targetCount, langCode, pad: false)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Row 5: Progress percentage
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.1,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  percentStr,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.groupNamjapProgress,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.appColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

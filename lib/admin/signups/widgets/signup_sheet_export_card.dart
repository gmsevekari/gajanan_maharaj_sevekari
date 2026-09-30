import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

class SignupSheetExportCard extends StatelessWidget {
  /// Fixed width of the exported PNG card in logical pixels.
  static const double _cardWidth = 380;

  final SignupSheet sheet;
  final List<SignupSlot> slots;
  final int totalClaims;
  final int totalCapacity;
  final String groupName;
  final AppLocalizations l10n;
  final ThemeData theme;
  final String langCode;

  const SignupSheetExportCard({
    super.key,
    required this.sheet,
    required this.slots,
    required this.totalClaims,
    required this.totalCapacity,
    required this.groupName,
    required this.l10n,
    required this.theme,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    final isMarathi = langCode == 'mr';
    final title = isMarathi
        ? (sheet.titleMr.isNotEmpty ? sheet.titleMr : sheet.titleEn)
        : (sheet.titleEn.isNotEmpty ? sheet.titleEn : sheet.titleMr);
    final desc = isMarathi ? sheet.descriptionMr : sheet.descriptionEn;

    final percentFilled = totalCapacity > 0
        ? ((totalClaims / totalCapacity) * 100).round()
        : 0;

    final totalSlotsStr = formatNumberLocalized(
      slots.length,
      langCode,
      pad: false,
    );
    final totalClaimsStr = formatNumberLocalized(
      totalClaims,
      langCode,
      pad: false,
    );
    final totalCapacityStr = formatNumberLocalized(
      totalCapacity,
      langCode,
      pad: false,
    );
    final percentStr =
        '${formatNumberLocalized(percentFilled, langCode, pad: false)}%';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: _cardWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  child: Icon(
                    Icons.event_note,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (groupName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          groupName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.appColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                desc,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.appColors.secondaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                _buildStatItem(
                  label: l10n.signupSheetTotalSlotsLabel,
                  value: totalSlotsStr,
                ),
                _buildStatItem(
                  label: l10n.signupSheetTotalClaimsLabel,
                  value: '$totalClaimsStr / $totalCapacityStr',
                ),
                _buildStatItem(
                  label: l10n.signupSheetFillPercentageLabel,
                  value: percentStr,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Slot progress list (up to 8 slots)
            ...slots.take(8).map((slot) {
              final slotLabel = isMarathi
                  ? (slot.labelMr.isNotEmpty ? slot.labelMr : slot.labelEn)
                  : (slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr);
              final progress = slot.capacity > 0
                  ? (slot.claimedCount / slot.capacity).clamp(0.0, 1.0)
                  : 0.0;
              final claimed = formatNumberLocalized(
                slot.claimedCount,
                langCode,
                pad: false,
              );
              final cap = formatNumberLocalized(
                slot.capacity,
                langCode,
                pad: false,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            slotLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          l10n.signupSheetSlotClaimedCount(claimed, cap),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.appColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0
                              ? theme.appColors.success
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),
            Text(
              l10n.signupSheetExportTagline,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.appColors.secondaryText,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.appColors.secondaryText,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

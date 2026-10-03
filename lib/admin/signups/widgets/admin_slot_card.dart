import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// A slot's summary - label, date, suggested amount and how full it is -
/// with an "Add Devotee" action. Used on [AdminSignupSlotsScreen]; the
/// slot's entries are listed on the Entries screen instead.
class AdminSlotCard extends StatelessWidget {
  final SignupSlot slot;
  final void Function(SignupSlot slot) onAddEntry;

  const AdminSlotCard({
    super.key,
    required this.slot,
    required this.onAddEntry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = contentIsMarathi(context);
    const langCode = 'en';

    final label = isMarathi
        ? (slot.labelMr.isNotEmpty ? slot.labelMr : slot.labelEn)
        : (slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr);

    final isFull = slot.claimedCount >= slot.capacity;
    final progress = slot.capacity > 0
        ? (slot.claimedCount / slot.capacity).clamp(0.0, 1.0)
        : 0.0;

    final claimedStr = formatNumberLocalized(
      slot.claimedCount,
      langCode,
      pad: false,
    );
    final capacityStr = formatNumberLocalized(
      slot.capacity,
      langCode,
      pad: false,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slot Title & Full Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isFull)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.appColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: theme.appColors.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      l10n.signupSlotFullBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.appColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Optional Date & Suggested Amount
            if (slot.date != null || slot.suggestedAmount != null) ...[
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (slot.date != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: theme.appColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDateShort(slot.date!, langCode),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.appColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  if (slot.suggestedAmount != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volunteer_activism_outlined,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.signupSuggestedAmountFormat(
                            slot.suggestedAmount.toString(),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Fill bar & progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.signupSlotClaimedCount(claimedStr, capacityStr),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isFull
                        ? theme.appColors.error
                        : theme.appColors.secondaryText,
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isFull
                        ? theme.appColors.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFull ? theme.appColors.error : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: Text(l10n.signupAddEntryButton),
                onPressed: () => onAddEntry(slot),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

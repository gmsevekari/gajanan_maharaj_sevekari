import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

/// A single claimable slot card on [SignupSheetDetailScreen]: its date and
/// live fill status, a Sign Up action (hidden once full), and the names of
/// devotees already signed up - no contact details, unlike the admin's
/// equivalent view, since this is visible to every devotee on the sheet.
class SignupSlotTile extends StatelessWidget {
  final SignupSlot slot;
  final List<SignupEntry> entries;
  final VoidCallback? onTap;

  const SignupSlotTile({
    super.key,
    required this.slot,
    required this.entries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    final langCode = isMarathi ? 'mr' : 'en';
    final isFull = slot.claimedCount >= slot.capacity;
    final label = slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr;
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
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Text(
                    l10n.signupSlotFullBadge,
                    style: TextStyle(
                      color: theme.appColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  ElevatedButton(
                    key: const Key('signUpButton'),
                    onPressed: onTap,
                    child: Text(l10n.signUp),
                  ),
              ],
            ),
            if (slot.date != null) ...[
              const SizedBox(height: 4),
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
            ],
            const SizedBox(height: 4),
            Text(
              l10n.signupSlotClaimedCount(claimedStr, capacityStr),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isFull
                    ? theme.appColors.error
                    : theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              l10n.signupSlotEntriesHeading,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            if (entries.isEmpty)
              Text(
                l10n.signupNoEntriesForSlot,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.appColors.secondaryText,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: theme.appColors.secondaryText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.name,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

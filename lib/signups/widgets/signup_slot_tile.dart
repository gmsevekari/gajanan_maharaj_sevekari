import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

/// A single claimable slot card on [SignupSlotsScreen]: its date and live
/// fill status, and a Sign Up action (hidden once full). Who's already
/// signed up is shown separately, in the signup's Entries table - not here.
class SignupSlotTile extends StatelessWidget {
  final SignupSlot slot;
  final VoidCallback? onTap;

  const SignupSlotTile({super.key, required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const langCode = 'en';
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
            if (slot.startAt != null) ...[
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
                    formatDateShortWithDay(slot.startAt!, langCode),
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
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';

/// A single claimable slot row on [SignupSheetDetailScreen], showing live
/// fill status. Disabled (and [onTap] ignored) once the slot is full.
class SignupSlotTile extends StatelessWidget {
  final SignupSlot slot;
  final VoidCallback? onTap;

  const SignupSlotTile({super.key, required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isFull = slot.claimedCount >= slot.capacity;
    final label = slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        enabled: !isFull,
        onTap: onTap,
        title: Text(label),
        subtitle: Text(
          l10n.signupSlotClaimedCount(
            slot.claimedCount.toString(),
            slot.capacity.toString(),
          ),
        ),
        trailing: isFull
            ? Text(
                l10n.signupSlotFullBadge,
                style: TextStyle(
                  color: theme.appColors.error,
                  fontWeight: FontWeight.bold,
                ),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

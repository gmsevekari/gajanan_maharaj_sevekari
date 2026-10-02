import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';

/// The devotee's own claimed entries on a sign-up sheet, each with a
/// Cancel action, shown in [SignupSheetDetailScreen]. Each entry shows
/// which [slots] it belongs to - an entry's own `slotId` would otherwise be
/// the only hint, and devotees reasonably want to know what they signed up
/// for without re-matching it against the slots list themselves.
class MySignupsSection extends StatelessWidget {
  final List<SignupEntry> entries;
  final List<SignupSlot> slots;
  final void Function(SignupEntry entry) onCancelEntry;

  const MySignupsSection({
    super.key,
    required this.entries,
    required this.slots,
    required this.onCancelEntry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';

    String slotLabelFor(String slotId) {
      final slot = slots.where((s) => s.id == slotId).firstOrNull;
      if (slot == null) return '';
      return isMarathi
          ? (slot.labelMr.isNotEmpty ? slot.labelMr : slot.labelEn)
          : (slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.signupMySignupsHeading,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.signupNoMySignups,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.appColors.secondaryText,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          for (final entry in entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(entry.name),
                subtitle: Text(slotLabelFor(entry.slotId)),
                trailing: TextButton(
                  onPressed: () => onCancelEntry(entry),
                  child: Text(l10n.signupCancelSignupButton),
                ),
              ),
            ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// A list of the devotee's own claimed entries, each showing which [slots]
/// it belongs to - an entry's own `slotId` would otherwise be the only
/// hint - and the phone and email it was made with, with optional Edit and
/// Cancel actions. Used as each tab's body on [MySignupsScreen];
/// [showCancelButton] and [showEditButton] are false on the Past tab, since
/// changing or cancelling a signup whose slot has already happened doesn't
/// apply.
class MySignupsSection extends StatelessWidget {
  final List<SignupEntry> entries;
  final List<SignupSlot> slots;
  final void Function(SignupEntry entry) onCancelEntry;
  final void Function(SignupEntry entry) onEditEntry;
  final bool showCancelButton;
  final bool showEditButton;
  final String emptyMessage;

  const MySignupsSection({
    super.key,
    required this.entries,
    required this.slots,
    required this.onCancelEntry,
    required this.onEditEntry,
    required this.emptyMessage,
    this.showCancelButton = true,
    this.showEditButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = contentIsMarathi(context);

    String slotLabelFor(String slotId) {
      final slot = slots.where((s) => s.id == slotId).firstOrNull;
      if (slot == null) return '';
      return isMarathi
          ? (slot.labelMr.isNotEmpty ? slot.labelMr : slot.labelEn)
          : (slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr);
    }

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            emptyMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.appColors.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in entries)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(entry.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slotLabelFor(entry.slotId)),
                  for (final detail in _details(entry)) Text(detail),
                ],
              ),
              trailing: showEditButton || showCancelButton
                  ? Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (showEditButton)
                          TextButton(
                            onPressed: () => onEditEntry(entry),
                            child: Text(l10n.signupEditEntryButton),
                          ),
                        if (showCancelButton)
                          TextButton(
                            onPressed: () => onCancelEntry(entry),
                            child: Text(l10n.signupCancelSignupButton),
                          ),
                      ],
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  /// The entry's phone and email, whichever it has.
  static List<String> _details(SignupEntry entry) => [
    for (final value in [entry.phone, entry.email])
      if (value != null && value.trim().isNotEmpty) value.trim(),
  ];
}

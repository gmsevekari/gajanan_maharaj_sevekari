import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';

/// The devotee's own claimed entries on a sign-up sheet, each with a
/// Cancel action, shown in [SignupSheetDetailScreen].
class MySignupsSection extends StatelessWidget {
  final List<SignupEntry> entries;
  final void Function(SignupEntry entry) onCancelEntry;

  const MySignupsSection({
    super.key,
    required this.entries,
    required this.onCancelEntry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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

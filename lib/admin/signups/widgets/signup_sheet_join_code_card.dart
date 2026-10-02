import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

/// A sign-up sheet's join code, with a copy-to-clipboard action. Shown in
/// [AdminSignupSheetDetailScreen] only when the sheet requires a join code.
class SignupSheetJoinCodeCard extends StatelessWidget {
  final String joinCode;

  const SignupSheetJoinCodeCard({super.key, required this.joinCode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.key, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.signupRequiresJoinCodeBadge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.appColors.secondaryText,
                    ),
                  ),
                  Text(
                    joinCode,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.signupCopyJoinCodeTooltip,
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: joinCode));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.joinCodeCopied)));
              },
            ),
          ],
        ),
      ),
    );
  }
}

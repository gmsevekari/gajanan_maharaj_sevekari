import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

/// A one-line note, shown on the web, saying why the sign-up buttons are
/// disabled: signing up (and claiming a sign-up) is done in the mobile app.
class SignupMobileAppNotice extends StatelessWidget {
  const SignupMobileAppNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.useMobileAppForSignups)),
          ],
        ),
      ),
    );
  }
}

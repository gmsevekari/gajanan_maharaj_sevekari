import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

/// Duplicate/Share/Export actions for [AdminSignupSheetDetailScreen].
class SignupSheetActionsRow extends StatelessWidget {
  final VoidCallback onDuplicate;
  final VoidCallback onShare;
  final VoidCallback onExport;

  const SignupSheetActionsRow({
    super.key,
    required this.onDuplicate,
    required this.onShare,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: Text(l10n.signupDuplicateButton),
          onPressed: onDuplicate,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.share, size: 16),
          label: Text(l10n.signupShareButton),
          onPressed: onShare,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.image_outlined, size: 16),
          label: Text(l10n.signupExportButton),
          onPressed: onExport,
        ),
      ],
    );
  }
}

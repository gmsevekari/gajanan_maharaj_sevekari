import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

/// Duplicate/Share/Export/Delete actions for [AdminSignupDetailScreen].
class SignupActionsRow extends StatelessWidget {
  final VoidCallback onDuplicate;
  final VoidCallback onShare;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const SignupActionsRow({
    super.key,
    required this.onDuplicate,
    required this.onShare,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: Text(l10n.signupDuplicateButton),
          onPressed: onDuplicate,
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.share, size: 16),
          label: Text(l10n.signupShareButton),
          onPressed: onShare,
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.image_outlined, size: 16),
          label: Text(l10n.signupExportButton),
          onPressed: onExport,
        ),
        ElevatedButton.icon(
          key: const Key('deleteSignupButton'),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: Text(l10n.signupDeleteButton),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: onDelete,
        ),
      ],
    );
  }
}

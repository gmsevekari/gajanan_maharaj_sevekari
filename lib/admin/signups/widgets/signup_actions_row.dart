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

    final duplicate = ElevatedButton.icon(
      icon: const Icon(Icons.copy, size: 16),
      label: Text(l10n.signupDuplicateButton),
      onPressed: onDuplicate,
    );
    final share = ElevatedButton.icon(
      icon: const Icon(Icons.share, size: 16),
      label: Text(l10n.signupShareButton),
      onPressed: onShare,
    );
    final export = ElevatedButton.icon(
      icon: const Icon(Icons.image_outlined, size: 16),
      label: Text(l10n.signupExportButton),
      onPressed: onExport,
    );
    final delete = ElevatedButton.icon(
      key: const Key('deleteSignupButton'),
      icon: const Icon(Icons.delete_outline, size: 16),
      label: Text(l10n.signupDeleteButton),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
      ),
      onPressed: onDelete,
    );

    // A 2x2 grid of equal-width buttons, so the actions line up instead of
    // wrapping ragged at whatever width each label happens to need.
    return Column(
      children: [
        _buttonPair(duplicate, share),
        const SizedBox(height: _gap),
        _buttonPair(export, delete),
      ],
    );
  }

  static const double _gap = 8;

  Widget _buttonPair(Widget left, Widget right) => Row(
    children: [
      Expanded(child: left),
      const SizedBox(width: _gap),
      Expanded(child: right),
    ],
  );
}

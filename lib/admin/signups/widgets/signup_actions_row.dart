import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

/// Duplicate, Share and the two exports (the summary image and the table of
/// sign-ups) for [AdminSignupDetailScreen]. Deleting a sign-up is on the
/// overview card, beside Edit.
class SignupActionsRow extends StatelessWidget {
  final VoidCallback onDuplicate;
  final VoidCallback onShare;
  final VoidCallback onExport;
  final VoidCallback onExportSignups;

  const SignupActionsRow({
    super.key,
    required this.onDuplicate,
    required this.onShare,
    required this.onExport,
    required this.onExportSignups,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
    final exportSignups = ElevatedButton.icon(
      key: const Key('exportSignupsButton'),
      icon: const Icon(Icons.table_chart_outlined, size: 16),
      label: Text(l10n.signupExportEntriesButton),
      onPressed: onExportSignups,
    );

    // A 2x2 grid of equal-width buttons, so the actions line up instead of
    // wrapping ragged at whatever width each label happens to need.
    return Column(
      children: [
        _buttonPair(duplicate, share),
        const SizedBox(height: _gap),
        _buttonPair(export, exportSignups),
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

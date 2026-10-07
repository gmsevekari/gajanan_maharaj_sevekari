import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// Wraps an edit screen so leaving it with unsaved changes asks "Discard
/// changes?" first (the back button and Android back; iOS's edge swipe can't
/// be intercepted). While [busy], such as mid-save, going back is ignored.
///
/// Programmatic `Navigator.pop`, as after a successful save, is not blocked.
class UnsavedChangesGuard extends StatelessWidget {
  final bool hasUnsavedChanges;
  final bool busy;
  final Widget child;

  const UnsavedChangesGuard({
    super.key,
    required this.hasUnsavedChanges,
    required this.child,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasUnsavedChanges && !busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || busy) return;
        _confirmDiscard(context);
      },
      child: child,
    );
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final discard = await showEnglishDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signupDiscardChangesTitle),
        content: Text(l10n.signupDiscardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.signupKeepEditingButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.discardLabel,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (discard == true && context.mounted) Navigator.pop(context);
  }
}

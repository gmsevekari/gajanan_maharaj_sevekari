import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';

/// A lock-guarded status segmented button for [AdminSignupSheetDetailScreen]
/// - starts locked so a stray tap can't change a published sheet's status,
/// and owns its own lock state since nothing outside this widget needs it.
class SignupSheetStatusSection extends StatefulWidget {
  final SignupSheetStatus currentStatus;
  final ValueChanged<SignupSheetStatus> onStatusChanged;

  const SignupSheetStatusSection({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  State<SignupSheetStatusSection> createState() =>
      _SignupSheetStatusSectionState();
}

class _SignupSheetStatusSectionState extends State<SignupSheetStatusSection> {
  bool _isLocked = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.signupStatusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: theme.appColors.secondaryText,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isLocked ? Icons.lock_outline : Icons.lock_open,
                    size: 20,
                    color: _isLocked
                        ? theme.appColors.secondaryText
                        : theme.colorScheme.primary,
                  ),
                  onPressed: () => setState(() => _isLocked = !_isLocked),
                ),
              ],
            ),
            const SizedBox(height: 8),
            IgnorePointer(
              ignoring: _isLocked,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isLocked ? 0.6 : 1.0,
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<SignupSheetStatus>(
                    segments: [
                      ButtonSegment(
                        value: SignupSheetStatus.draft,
                        label: Text(l10n.signupStatusDraft),
                      ),
                      ButtonSegment(
                        value: SignupSheetStatus.published,
                        label: Text(l10n.signupStatusPublished),
                      ),
                      ButtonSegment(
                        value: SignupSheetStatus.closed,
                        label: Text(l10n.signupStatusClosed),
                      ),
                    ],
                    selected: {widget.currentStatus},
                    onSelectionChanged: (selected) {
                      final newStatus = selected.firstOrNull;
                      if (newStatus != null &&
                          newStatus != widget.currentStatus) {
                        widget.onStatusChanged(newStatus);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

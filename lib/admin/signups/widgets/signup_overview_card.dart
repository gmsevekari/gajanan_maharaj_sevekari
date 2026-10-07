import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_join_code_row.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';

/// A sign-up's title, group chip, status and (when one is required) join
/// code, shown at the top of [AdminSignupDetailScreen], with an Edit button
/// for the title, description and join code and a Delete button for the whole
/// sign-up. The status here is read-only; it is changed with
/// [SignupStatusSection].
///
/// Delete only asks [onDelete] to start; confirming it is the caller's job.
class SignupOverviewCard extends StatelessWidget {
  final String title;
  final String groupName;
  final SignupStatus status;

  /// Null when the signup doesn't require a join code.
  final String? joinCode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SignupOverviewCard({
    super.key,
    required this.title,
    required this.groupName,
    required this.status,
    required this.onEdit,
    required this.onDelete,
    this.joinCode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final code = joinCode;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (groupName.isNotEmpty)
                  Flexible(
                    child: Chip(
                      label: Text(groupName, overflow: TextOverflow.ellipsis),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Wraps, not a Row: at large text the status and the two buttons
            // no longer fit on one line, and the buttons drop below it (and,
            // if need be, below each other).
            SizedBox(
              // Full width, or the Wrap shrinks to its content and the buttons
              // sit beside the status instead of at the card's edge.
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusChip(status: status),
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        key: const Key('deleteSignupButton'),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(l10n.signupDeleteButton),
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(l10n.signupEditSignupButton),
                        onPressed: onEdit,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (code != null) ...[
              const SizedBox(height: 8),
              SignupJoinCodeRow(joinCode: code),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SignupStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      SignupStatus.published => (
        l10n.signupStatusPublished,
        theme.appColors.success,
      ),
      SignupStatus.closed => (l10n.signupStatusClosed, theme.colorScheme.error),
      SignupStatus.draft => (
        l10n.signupStatusDraft,
        theme.appColors.secondaryText,
      ),
    };

    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide.none,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

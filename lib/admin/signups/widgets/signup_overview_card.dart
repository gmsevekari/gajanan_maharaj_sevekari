import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_join_code_row.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';

/// A sign-up's title, group chip, status and (when one is required) join
/// code, shown at the top of [AdminSignupDetailScreen]. The status here is
/// read-only; it is changed with [SignupStatusSection].
class SignupOverviewCard extends StatelessWidget {
  final String title;
  final String groupName;
  final SignupStatus status;

  /// Null when the signup doesn't require a join code.
  final String? joinCode;

  const SignupOverviewCard({
    super.key,
    required this.title,
    required this.groupName,
    required this.status,
    this.joinCode,
  });

  @override
  Widget build(BuildContext context) {
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
                  Chip(
                    label: Text(groupName),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _StatusChip(status: status),
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

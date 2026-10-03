import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/widgets/participant_contact_actions.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';

/// One devotee's entry: name, contact details with text/WhatsApp actions,
/// pledge and note, plus edit and remove buttons.
class AdminEntryTile extends StatelessWidget {
  final SignupEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const AdminEntryTile({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.appColors.disabledBackground.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: l10n.signupEditEntryTitle,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onEdit,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                tooltip: l10n.signupRemoveEntryTitle,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onRemove,
              ),
            ],
          ),
          if (entry.phone != null && entry.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: theme.appColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    entry.phone!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.appColors.secondaryText,
                    ),
                  ),
                ),
                ParticipantContactActions(
                  phone: entry.phone!,
                  textTooltip: l10n.sendTextTooltip,
                  whatsAppTooltip: l10n.whatsapp,
                ),
              ],
            ),
          ],
          if (entry.email != null && entry.email!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: theme.appColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  entry.email!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.appColors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
          if (entry.pledgeAmount != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.monetization_on_outlined,
                  size: 14,
                  color: theme.appColors.brandAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.pledgeAmount}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.appColors.brandAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.appColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

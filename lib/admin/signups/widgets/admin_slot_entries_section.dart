import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/widgets/participant_contact_actions.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

class AdminSlotEntriesSection extends StatelessWidget {
  final SignupSlot slot;
  final List<SignupEntry> entries;
  final void Function(SignupSlot slot) onAddEntry;
  final void Function(SignupEntry entry, SignupSlot slot) onEditEntry;
  final void Function(SignupEntry entry) onRemoveEntry;

  const AdminSlotEntriesSection({
    super.key,
    required this.slot,
    required this.entries,
    required this.onAddEntry,
    required this.onEditEntry,
    required this.onRemoveEntry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    final langCode = isMarathi ? 'mr' : 'en';

    final label = isMarathi
        ? (slot.labelMr.isNotEmpty ? slot.labelMr : slot.labelEn)
        : (slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr);

    final isFull = slot.claimedCount >= slot.capacity;
    final progress = slot.capacity > 0
        ? (slot.claimedCount / slot.capacity).clamp(0.0, 1.0)
        : 0.0;

    final claimedStr = formatNumberLocalized(
      slot.claimedCount,
      langCode,
      pad: false,
    );
    final capacityStr = formatNumberLocalized(
      slot.capacity,
      langCode,
      pad: false,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slot Title & Full Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isFull)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.appColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: theme.appColors.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      l10n.signupSlotFullBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.appColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Optional Date & Suggested Amount
            if (slot.date != null || slot.suggestedAmount != null) ...[
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (slot.date != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: theme.appColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDateShort(slot.date!, langCode),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.appColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  if (slot.suggestedAmount != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volunteer_activism_outlined,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.signupSuggestedAmountFormat(
                            slot.suggestedAmount.toString(),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Fill bar & progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.signupSlotClaimedCount(claimedStr, capacityStr),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isFull
                        ? theme.appColors.error
                        : theme.appColors.secondaryText,
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isFull
                        ? theme.appColors.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFull ? theme.appColors.error : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Entries section header with "Add Devotee" button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.signupSlotsHeading} (${entries.length})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.appColors.secondaryText,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: Text(l10n.signupAddEntryButton),
                  onPressed: () => onAddEntry(slot),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Entries list
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.signupNoEntriesForSlot,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.appColors.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...entries.map((entry) => _buildEntryRow(entry, l10n, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(
    SignupEntry entry,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
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
                onPressed: () => onEditEntry(entry, slot),
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
                onPressed: () => onRemoveEntry(entry),
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

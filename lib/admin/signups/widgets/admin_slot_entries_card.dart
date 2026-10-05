import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_entry_tile.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/slot_when_view.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// The entries signed up for one slot, under the slot's title and date. Used
/// on [AdminSignupEntriesScreen].
class AdminSlotEntriesCard extends StatelessWidget {
  final SignupSlot slot;
  final List<SignupEntry> entries;
  final void Function(SignupEntry entry) onEditEntry;
  final void Function(SignupEntry entry) onRemoveEntry;

  const AdminSlotEntriesCard({
    super.key,
    required this.slot,
    required this.entries,
    required this.onEditEntry,
    required this.onRemoveEntry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMarathi = contentIsMarathi(context);
    final label = isMarathi
        ? (slot.labelMr.isNotEmpty ? slot.labelMr : slot.labelEn)
        : (slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (slot.hasSchedule) ...[
              const SizedBox(height: 4),
              SlotWhenView(slot: slot),
            ],
            const SizedBox(height: 12),
            for (final entry in entries)
              AdminEntryTile(
                entry: entry,
                onEdit: () => onEditEntry(entry),
                onRemove: () => onRemoveEntry(entry),
              ),
          ],
        ),
      ),
    );
  }
}

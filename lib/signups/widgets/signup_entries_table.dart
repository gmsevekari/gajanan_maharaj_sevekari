import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// Every entry in [entries] as a table row (Date, Title, Name, Available
/// Slots), sorted by its slot's date (undated slots last) then by name. A
/// Table rather than a DataTable so the columns share the screen width and
/// their text wraps instead of the table growing wider than the screen.
class SignupEntriesTable extends StatelessWidget {
  final List<SignupEntry> entries;
  final List<SignupSlot> slots;

  const SignupEntriesTable({
    super.key,
    required this.entries,
    required this.slots,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = contentIsMarathi(context);

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            l10n.signupEntriesEmptyMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.appColors.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final slotsById = {for (final slot in slots) slot.id: slot};

    final rows = entries.toList()
      ..sort((a, b) {
        final dateA = slotsById[a.slotId]?.date;
        final dateB = slotsById[b.slotId]?.date;
        if (dateA == null && dateB != null) return 1;
        if (dateA != null && dateB == null) return -1;
        if (dateA != null && dateB != null) {
          final cmp = dateA.compareTo(dateB);
          if (cmp != 0) return cmp;
        }
        return a.name.compareTo(b.name);
      });

    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final cellStyle = theme.textTheme.bodyMedium;
    final divider = BorderSide(
      color: theme.dividerColor.withValues(alpha: 0.5),
    );

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(2),
      },
      border: TableBorder(horizontalInside: divider, bottom: divider),
      children: [
        TableRow(
          children: [
            _cell(l10n.date, headerStyle),
            _cell(l10n.signupEntriesTitleColumn, headerStyle),
            _cell(l10n.name, headerStyle),
            _cell(l10n.signupEntriesAvailableSlotsColumn, headerStyle),
          ],
        ),
        for (final entry in rows)
          TableRow(
            children: [
              _cell(
                slotsById[entry.slotId]?.date != null
                    ? formatDateShort(slotsById[entry.slotId]!.date!, 'en')
                    : '-',
                cellStyle,
              ),
              _cell(_slotLabel(slotsById[entry.slotId], isMarathi), cellStyle),
              _cell(entry.name, cellStyle),
              _cell(_availableSlots(slotsById[entry.slotId]), cellStyle),
            ],
          ),
      ],
    );
  }

  Widget _cell(String text, TextStyle? style) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    child: Text(text, style: style),
  );

  String _slotLabel(SignupSlot? slot, bool isMarathi) {
    if (slot == null) return '';
    return isMarathi
        ? (slot.labelMr.isNotEmpty ? slot.labelMr : slot.labelEn)
        : (slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr);
  }

  String _availableSlots(SignupSlot? slot) {
    if (slot == null) return '-';
    return (slot.capacity - slot.claimedCount)
        .clamp(0, slot.capacity)
        .toString();
  }
}

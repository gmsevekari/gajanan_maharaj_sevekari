import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// Every entry in [entries] as a table row (Date, Title, Name), sorted by
/// its slot's date (undated slots last), then by the slot's own order so one
/// slot's entries stay together when several slots share a date, then by
/// name. A Table rather than a DataTable so the columns share the screen
/// width and their text wraps instead of the table growing wider than the
/// screen.
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
      ..sort((a, b) => _compareEntries(a, b, slotsById));

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
      },
      border: TableBorder(horizontalInside: divider, bottom: divider),
      children: [
        TableRow(
          children: [
            _cell(l10n.date, headerStyle),
            _cell(l10n.signupEntriesTitleColumn, headerStyle),
            _cell(l10n.name, headerStyle),
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

  /// Date (undated last), then slot order, then slot id (so slots that tie on
  /// both still group), then name.
  static int _compareEntries(
    SignupEntry a,
    SignupEntry b,
    Map<String?, SignupSlot> slotsById,
  ) {
    final slotA = slotsById[a.slotId];
    final slotB = slotsById[b.slotId];
    final dateA = slotA?.date;
    final dateB = slotB?.date;
    if (dateA == null && dateB != null) return 1;
    if (dateA != null && dateB == null) return -1;
    if (dateA != null && dateB != null) {
      final byDate = dateA.compareTo(dateB);
      if (byDate != 0) return byDate;
    }
    final bySlotOrder = (slotA?.sortOrder ?? 0).compareTo(
      slotB?.sortOrder ?? 0,
    );
    if (bySlotOrder != 0) return bySlotOrder;
    final bySlot = a.slotId.compareTo(b.slotId);
    if (bySlot != 0) return bySlot;
    return a.name.compareTo(b.name);
  }
}

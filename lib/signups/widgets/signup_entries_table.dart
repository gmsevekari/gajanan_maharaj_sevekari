import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/slot_when_view.dart';
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
      ..sort((a, b) => compareEntries(a, b, slotsById));

    final headerStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.secondary,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );
    final cellStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
    );
    final cardColor =
        theme.cardTheme.color ?? theme.colorScheme.surfaceContainer;
    final bandBorder = BorderSide(
      color: theme.colorScheme.primary.withValues(alpha: 0.2),
    );

    // Entries arrive sorted, so each slot's entries are adjacent. Group them
    // so a slot reads as one block, with the block tint alternating.
    final groups = <List<SignupEntry>>[];
    for (final entry in rows) {
      if (groups.isNotEmpty && groups.last.first.slotId == entry.slotId) {
        groups.last.add(entry);
      } else {
        groups.add([entry]);
      }
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Table(
            columnWidths: _columnWidths,
            children: [
              TableRow(
                children: [
                  _cell(l10n.date, headerStyle, vertical: 14),
                  _cell(
                    l10n.signupEntriesTitleColumn,
                    headerStyle,
                    vertical: 14,
                  ),
                  _cell(l10n.name, headerStyle, vertical: 14),
                ],
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < groups.length; i++)
                Container(
                  key: Key('entriesGroup_$i'),
                  decoration: BoxDecoration(
                    color: i.isEven
                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    border: Border(top: i > 0 ? bandBorder : BorderSide.none),
                  ),
                  child: Table(
                    columnWidths: _columnWidths,
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      for (var j = 0; j < groups[i].length; j++)
                        TableRow(
                          children: [
                            // Date and title are the slot's, so they show
                            // once, on its first row.
                            j == 0
                                ? _dateCell(
                                    slotsById[groups[i][j].slotId],
                                    cellStyle,
                                  )
                                : _cell('', cellStyle),
                            _cell(
                              j == 0
                                  ? _slotLabel(
                                      slotsById[groups[i][j].slotId],
                                      isMarathi,
                                    )
                                  : '',
                              cellStyle,
                            ),
                            _cell(groups[i][j].name, cellStyle),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The Date column is the widest: it holds a weekday date and a time range,
  /// which break mid-word in a narrower column on a phone.
  static const Map<int, TableColumnWidth> _columnWidths = {
    0: FlexColumnWidth(3),
    1: FlexColumnWidth(2),
    2: FlexColumnWidth(2),
  };

  Widget _cell(String text, TextStyle? style, {double vertical = 12}) =>
      _padded(Text(text, style: style), vertical: vertical);

  Widget _padded(Widget child, {double vertical = 12}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: vertical),
    child: child,
  );

  /// The slot's date, with its time range under it when it has one; a dash
  /// when the slot has no schedule.
  Widget _dateCell(SignupSlot? slot, TextStyle? style) {
    if (slot == null || !slot.hasSchedule) return _cell('-', style);
    return _padded(SlotWhenView(slot: slot, showIcon: false, style: style));
  }

  String _slotLabel(SignupSlot? slot, bool isMarathi) {
    if (slot == null) return '';
    return isMarathi
        ? (slot.labelMr.isNotEmpty ? slot.labelMr : slot.labelEn)
        : (slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr);
  }

  /// Slot start (undated last, then slot order - see
  /// [SignupSlot.compareByStart]), then slot id (so slots that tie on both
  /// still group), then name. An entry whose slot is gone comes last.
  @visibleForTesting
  static int compareEntries(
    SignupEntry a,
    SignupEntry b,
    Map<String?, SignupSlot> slotsById,
  ) {
    final slotA = slotsById[a.slotId];
    final slotB = slotsById[b.slotId];
    if (slotA == null && slotB != null) return 1;
    if (slotA != null && slotB == null) return -1;
    if (slotA != null && slotB != null) {
      final byStart = SignupSlot.compareByStart(slotA, slotB);
      if (byStart != 0) return byStart;
    }
    final bySlot = a.slotId.compareTo(b.slotId);
    if (bySlot != 0) return bySlot;
    return a.name.compareTo(b.name);
  }
}

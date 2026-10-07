import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_format.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// Asks which of [slots] to export the sign-ups of. Only slots that haven't
/// finished by [now] are offered; resolves to the ones the admin ticked, in
/// date order, or null when the dialog is cancelled.
Future<List<SignupSlot>?> showExportSlotsDialog({
  required BuildContext context,
  required List<SignupSlot> slots,
  required DateTime now,
}) => showEnglishDialog<List<SignupSlot>>(
  context: context,
  builder: (_) => ExportSlotsDialog(slots: slots, now: now),
);

/// The picker behind [showExportSlotsDialog]: the upcoming slots as
/// checkboxes, all ticked to begin with, under a "Select all" box.
class ExportSlotsDialog extends StatefulWidget {
  final List<SignupSlot> slots;
  final DateTime now;

  const ExportSlotsDialog({super.key, required this.slots, required this.now});

  @override
  State<ExportSlotsDialog> createState() => _ExportSlotsDialogState();
}

class _ExportSlotsDialogState extends State<ExportSlotsDialog> {
  /// The slots on offer, soonest first (undated last).
  late final List<SignupSlot> _upcoming = [
    for (final slot in widget.slots)
      if (!slot.isPast(widget.now)) slot,
  ]..sort(SignupSlot.compareByStart);

  /// Indexes into [_upcoming] that are ticked.
  late Set<int> _selected = {for (var i = 0; i < _upcoming.length; i++) i};

  bool get _allSelected => _selected.length == _upcoming.length;

  void _toggle(int index) {
    final next = {..._selected};
    if (!next.remove(index)) next.add(index);
    setState(() => _selected = next);
  }

  /// Ticks everything, unless everything is ticked already.
  void _toggleAll() => setState(
    () => _selected = _allSelected
        ? <int>{}
        : {for (var i = 0; i < _upcoming.length; i++) i},
  );

  List<SignupSlot> _chosen() => [
    for (var i = 0; i < _upcoming.length; i++)
      if (_selected.contains(i)) _upcoming[i],
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.signupExportEntriesTitle),
      scrollable: true,
      content: _upcoming.isEmpty
          ? Text(l10n.signupExportNoUpcomingSlots)
          : _buildChoices(context, l10n),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        if (_upcoming.isNotEmpty)
          TextButton(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.of(context).pop(_chosen()),
            child: Text(l10n.signupExportConfirm),
          ),
      ],
    );
  }

  Widget _buildChoices(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.signupExportEntriesPrompt,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.appColors.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          tristate: true,
          value: _allSelected ? true : (_selected.isEmpty ? false : null),
          onChanged: (_) => _toggleAll(),
          title: Text(
            l10n.signupExportSelectAll,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        for (var i = 0; i < _upcoming.length; i++)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _selected.contains(i),
            onChanged: (_) => _toggle(i),
            title: Text(_label(context, _upcoming[i])),
            subtitle: _buildSubtitle(context, l10n, _upcoming[i]),
          ),
      ],
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    AppLocalizations l10n,
    SignupSlot slot,
  ) {
    final when = formatSlotWhen(slot);
    final claimed = formatNumberLocalized(slot.claimedCount, 'en', pad: false);
    final capacity = formatNumberLocalized(slot.capacity, 'en', pad: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (when != null) Text(when.primary),
        if (when?.secondary != null) Text(when!.secondary!),
        Text(l10n.signupSlotClaimedCount(claimed, capacity)),
      ],
    );
  }

  String _label(BuildContext context, SignupSlot slot) =>
      contentIsMarathi(context)
      ? (slot.labelMr.isNotEmpty ? slot.labelMr : slot.labelEn)
      : (slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr);
}

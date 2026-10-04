import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_format.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_schedule.dart';

/// The schedule inputs for one slot: start and end date and time, and the
/// timezone they are entered in.
///
/// ```
/// Starts    [ Mar 15, 2026 ]  [ 6:00 PM  x ]
/// Ends      [ Mar 15, 2026 ]  [ 7:30 PM  x ]
/// Timezone  [ Seattle (Pacific Time)     v ]
/// ```
///
/// It is a [FormField] of [SlotScheduleInput], validated through
/// [resolveSlotSchedule]: a start date is required and the end must be after
/// the start. The error shows under the inputs and clears as soon as the
/// input becomes valid. [initialValue] is only read once; afterwards the
/// field owns the value and reports each change through [onChanged].
///
/// The end date follows the start date until the admin sets it to something
/// else; empty times show the default they stand for (12:00 AM / 11:59 PM)
/// as a hint.
class SlotScheduleField extends FormField<SlotScheduleInput> {
  SlotScheduleField({
    super.key,
    required int index,
    required SlotScheduleInput initialValue,
    required String dateRequiredMessage,
    required String endNotAfterStartMessage,
    required ValueChanged<SlotScheduleInput> onChanged,
  }) : super(
         initialValue: initialValue,
         autovalidateMode: AutovalidateMode.onUserInteraction,
         validator: (value) => switch (resolveSlotSchedule(value!)) {
           SlotScheduleResolved() => null,
           SlotScheduleInvalid(:final error) => switch (error) {
             SlotScheduleError.missingStartDate => dateRequiredMessage,
             SlotScheduleError.endNotAfterStart => endNotAfterStartMessage,
           },
         },
         builder: (state) => _SlotScheduleBody(
           index: index,
           state: state,
           onChanged: onChanged,
         ),
       );
}

/// How far back and forward a slot date can be picked. Offsets from "now"
/// rather than fixed calendar years, so they don't need bumping as years pass.
const Duration _pastHorizon = Duration(days: 30);
const Duration _futureHorizon = Duration(days: 365 * 5);

class _SlotScheduleBody extends StatelessWidget {
  final int index;
  final FormFieldState<SlotScheduleInput> state;
  final ValueChanged<SlotScheduleInput> onChanged;

  const _SlotScheduleBody({
    required this.index,
    required this.state,
    required this.onChanged,
  });

  SlotScheduleInput get _value => state.value!;

  void _update(SlotScheduleInput next) {
    state.didChange(next);
    onChanged(next);
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _clamp(
        _value.startDate ?? now,
        now.subtract(_pastHorizon),
        now.add(_futureHorizon),
      ),
      firstDate: now.subtract(_pastHorizon),
      lastDate: now.add(_futureHorizon),
    );
    if (picked == null) return;
    // An end on the same day (or none yet) moves with the start; one the
    // admin set to a different day stays where it is.
    final endFollowsStart =
        _value.endDate == null || _sameDay(_value.endDate!, _value.startDate);
    _update(
      _value.copyWith(
        startDate: picked,
        endDate: endFollowsStart ? picked : null,
      ),
    );
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final earliest = _dateOnly(_value.startDate ?? now.subtract(_pastHorizon));
    final latest = now.add(_futureHorizon);
    final picked = await showDatePicker(
      context: context,
      initialDate: _clamp(
        _value.endDate ?? _value.startDate ?? now,
        earliest,
        latest,
      ),
      firstDate: earliest,
      lastDate: latest,
    );
    if (picked != null) _update(_value.copyWith(endDate: picked));
  }

  Future<ClockTime?> _pickTime(
    BuildContext context, {
    required ClockTime initial,
    required String helpText,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      helpText: helpText,
    );
    return picked == null ? null : (hour: picked.hour, minute: picked.minute);
  }

  Future<void> _pickStartTime(BuildContext context, String helpText) async {
    final picked = await _pickTime(
      context,
      initial: _value.startTime ?? slotPickerStartTime,
      helpText: helpText,
    );
    if (picked != null) _update(_value.copyWith(startTime: picked));
  }

  Future<void> _pickEndTime(BuildContext context, String helpText) async {
    final picked = await _pickTime(
      context,
      initial: _value.endTime ?? suggestedSlotEndTime(_value.startTime),
      helpText: helpText,
    );
    if (picked != null) _update(_value.copyWith(endTime: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final value = _value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(l10n.signupSlotStartsLabel),
        Row(
          children: [
            Expanded(
              child: _PickerButton(
                key: Key('slotStartDate_$index'),
                text: value.startDate == null
                    ? l10n.selectDate
                    : formatSlotInputDate(value.startDate!),
                isHint: value.startDate == null,
                onPressed: () => _pickStartDate(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PickerButton(
                key: Key('slotStartTime_$index'),
                text: formatClockTime(value.startTime ?? slotDefaultStartTime),
                isHint: value.startTime == null,
                onPressed: () =>
                    _pickStartTime(context, l10n.signupSlotStartTimeLabel),
                clearKey: value.startTime == null
                    ? null
                    : Key('slotClearStartTime_$index'),
                clearTooltip: l10n.signupSlotClearTimeTooltip,
                onClear: () => _update(_value.copyWith(clearStartTime: true)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SectionLabel(l10n.signupSlotEndsLabel),
        Row(
          children: [
            Expanded(
              child: _PickerButton(
                key: Key('slotEndDate_$index'),
                text: value.endDate == null
                    ? l10n.selectDate
                    : formatSlotInputDate(value.endDate!),
                isHint: value.endDate == null,
                onPressed: () => _pickEndDate(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PickerButton(
                key: Key('slotEndTime_$index'),
                text: formatClockTime(value.endTime ?? slotDefaultEndTime),
                isHint: value.endTime == null,
                onPressed: () =>
                    _pickEndTime(context, l10n.signupSlotEndTimeLabel),
                clearKey: value.endTime == null
                    ? null
                    : Key('slotClearEndTime_$index'),
                clearTooltip: l10n.signupSlotClearTimeTooltip,
                onClear: () => _update(_value.copyWith(clearEndTime: true)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: Key('slotTimezone_$index'),
          initialValue: normalizeTimezone(value.timezone),
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.timezoneLabel,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            for (final zone in EventTimezone.supported)
              DropdownMenuItem(
                value: zone,
                child: Text(
                  zone == EventTimezone.india
                      ? l10n.timezoneIndia
                      : l10n.timezoneSeattle,
                ),
              ),
          ],
          onChanged: (zone) {
            if (zone != null) _update(_value.copyWith(timezone: zone));
          },
        ),
        if (state.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              state.errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.appColors.secondaryText,
        ),
      ),
    );
  }
}

/// An outlined button showing a picked value, or a muted hint when empty,
/// with an optional clear button inside it.
class _PickerButton extends StatelessWidget {
  final String text;
  final bool isHint;
  final VoidCallback onPressed;
  final Key? clearKey;
  final String? clearTooltip;
  final VoidCallback? onClear;

  const _PickerButton({
    super.key,
    required this.text,
    required this.isHint,
    required this.onPressed,
    this.clearKey,
    this.clearTooltip,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 10, right: 4),
        visualDensity: VisualDensity.compact,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: isHint
                  ? TextStyle(color: theme.appColors.secondaryText)
                  : null,
            ),
          ),
          if (clearKey != null)
            IconButton(
              key: clearKey,
              icon: const Icon(Icons.clear, size: 16),
              tooltip: clearTooltip,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onClear,
            )
          else
            const SizedBox(width: 6),
        ],
      ),
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime? b) =>
    b != null && a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _clamp(DateTime d, DateTime lo, DateTime hi) =>
    d.isBefore(lo) ? lo : (d.isAfter(hi) ? hi : d);

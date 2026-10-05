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
/// The end date follows the start date until the admin picks one themselves;
/// from then on it stays where they put it, even if it later equals the start.
/// Empty times show the default they stand for (12:00 AM / 11:59 PM) as a
/// hint. The pickers always open in English, like the rest of the sign-up
/// screens, whatever the app language.
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

const Locale _english = Locale('en');

class _SlotScheduleBody extends StatefulWidget {
  final int index;
  final FormFieldState<SlotScheduleInput> state;
  final ValueChanged<SlotScheduleInput> onChanged;

  const _SlotScheduleBody({
    required this.index,
    required this.state,
    required this.onChanged,
  });

  @override
  State<_SlotScheduleBody> createState() => _SlotScheduleBodyState();
}

class _SlotScheduleBodyState extends State<_SlotScheduleBody> {
  /// Whether the admin has picked the end date themselves. Until then it
  /// follows the start date. A schedule that arrives with an end on a
  /// different day than its start counts as chosen.
  late bool _endDateIsManual;

  SlotScheduleInput get _value => widget.state.value!;

  @override
  void initState() {
    super.initState();
    final value = _value;
    _endDateIsManual =
        value.endDate != null && !_sameDay(value.endDate!, value.startDate);
  }

  void _update(SlotScheduleInput next) {
    if (!widget.state.mounted) return; // a picker outlived the screen
    widget.state.didChange(next);
    widget.onChanged(next);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final first = now.subtract(_pastHorizon);
    final last = now.add(_futureHorizon);
    final picked = await showDatePicker(
      context: context,
      locale: _english,
      initialDate: _clamp(_value.startDate ?? now, first, last),
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return;
    _update(
      _value.copyWith(
        startDate: picked,
        endDate: _endDateIsManual ? null : picked,
      ),
    );
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final last = now.add(_futureHorizon);
    // Not before the start, but never after the last pickable day either.
    final first = _clamp(
      _dateOnly(_value.startDate ?? now.subtract(_pastHorizon)),
      DateTime(1970),
      last,
    );
    final picked = await showDatePicker(
      context: context,
      locale: _english,
      initialDate: _clamp(
        _value.endDate ?? _value.startDate ?? now,
        first,
        last,
      ),
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return;
    _endDateIsManual = true;
    _update(_value.copyWith(endDate: picked));
  }

  Future<ClockTime?> _pickTime(ClockTime initial, String helpText) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      helpText: helpText,
      builder: (context, child) => Localizations.override(
        context: context,
        locale: _english,
        child: child!,
      ),
    );
    return picked == null ? null : (hour: picked.hour, minute: picked.minute);
  }

  Future<void> _pickStartTime(String helpText) async {
    final picked = await _pickTime(
      _value.startTime ?? slotPickerStartTime,
      helpText,
    );
    if (picked != null) _update(_value.copyWith(startTime: picked));
  }

  Future<void> _pickEndTime(String helpText) async {
    final picked = await _pickTime(
      _value.endTime ?? suggestedSlotEndTime(_value.startTime),
      helpText,
    );
    if (picked != null) _update(_value.copyWith(endTime: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = _value;
    final index = widget.index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateTimeRow(
          heading: l10n.signupSlotStartsLabel,
          part: 'Start',
          index: index,
          dateLabel: l10n.startDateLabel,
          timeLabel: l10n.signupSlotStartTimeLabel,
          selectDateText: l10n.selectDate,
          optionalHint: l10n.signupSlotTimeOptionalLabel,
          clearTooltip:
              '${l10n.signupSlotClearTimeTooltip}: '
              '${l10n.signupSlotStartTimeLabel}',
          date: value.startDate,
          time: value.startTime,
          defaultTime: slotDefaultStartTime,
          onPickDate: _pickStartDate,
          onPickTime: () => _pickStartTime(l10n.signupSlotStartTimeLabel),
          onClearTime: () => _update(value.copyWith(clearStartTime: true)),
        ),
        const SizedBox(height: 8),
        _DateTimeRow(
          heading: l10n.signupSlotEndsLabel,
          part: 'End',
          index: index,
          dateLabel: l10n.endDateLabel,
          timeLabel: l10n.signupSlotEndTimeLabel,
          selectDateText: l10n.selectDate,
          optionalHint: l10n.signupSlotTimeOptionalLabel,
          clearTooltip:
              '${l10n.signupSlotClearTimeTooltip}: '
              '${l10n.signupSlotEndTimeLabel}',
          date: value.endDate,
          time: value.endTime,
          defaultTime: slotDefaultEndTime,
          onPickDate: _pickEndDate,
          onPickTime: () => _pickEndTime(l10n.signupSlotEndTimeLabel),
          onClearTime: () => _update(value.copyWith(clearEndTime: true)),
        ),
        if (widget.state.hasError) _ErrorText(widget.state.errorText!),
        const SizedBox(height: 12),
        _TimezoneDropdown(
          index: index,
          timezone: value.timezone,
          onChanged: (zone) => _update(value.copyWith(timezone: zone)),
        ),
      ],
    );
  }
}

/// A "Starts" or "Ends" heading over its date button and time button.
class _DateTimeRow extends StatelessWidget {
  final String heading;

  /// `Start` or `End`: part of the buttons' keys.
  final String part;
  final int index;
  final String dateLabel;
  final String timeLabel;
  final String selectDateText;
  final String optionalHint;
  final String clearTooltip;
  final DateTime? date;
  final ClockTime? time;
  final ClockTime defaultTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onClearTime;

  const _DateTimeRow({
    required this.heading,
    required this.part,
    required this.index,
    required this.dateLabel,
    required this.timeLabel,
    required this.selectDateText,
    required this.optionalHint,
    required this.clearTooltip,
    required this.date,
    required this.time,
    required this.defaultTime,
    required this.onPickDate,
    required this.onPickTime,
    required this.onClearTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            heading,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.appColors.secondaryText,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _PickerButton(
                buttonKey: Key('slot${part}Date_$index'),
                semanticsLabel: dateLabel,
                text: date == null
                    ? selectDateText
                    : formatSlotInputDate(date!),
                isHint: date == null,
                onPressed: onPickDate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PickerButton(
                buttonKey: Key('slot${part}Time_$index'),
                semanticsLabel: timeLabel,
                semanticsHint: time == null ? optionalHint : null,
                text: formatClockTime(time ?? defaultTime),
                isHint: time == null,
                onPressed: onPickTime,
                clearKey: time == null
                    ? null
                    : Key('slotClear${part}Time_$index'),
                clearTooltip: clearTooltip,
                onClear: onClearTime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// An outlined button showing a picked value, or a muted hint when empty,
/// with an optional clear button over its right edge. Screen readers hear its
/// [semanticsLabel] and the value; the clear button is announced separately.
class _PickerButton extends StatelessWidget {
  static const double _clearButtonRoom = 34;

  final Key buttonKey;
  final String semanticsLabel;
  final String? semanticsHint;
  final String text;
  final bool isHint;
  final VoidCallback onPressed;
  final Key? clearKey;
  final String? clearTooltip;
  final VoidCallback? onClear;

  const _PickerButton({
    required this.buttonKey,
    required this.semanticsLabel,
    required this.text,
    required this.isHint,
    required this.onPressed,
    this.semanticsHint,
    this.clearKey,
    this.clearTooltip,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasClear = clearKey != null;
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Semantics(
          label: semanticsLabel,
          value: text,
          hint: semanticsHint,
          button: true,
          enabled: true,
          onTap: onPressed,
          excludeSemantics: true,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: buttonKey,
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(
                  left: 10,
                  right: hasClear ? _clearButtonRoom : 10,
                ),
                visualDensity: VisualDensity.compact,
              ),
              // Shrinks rather than cuts off at large text sizes.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  maxLines: 1,
                  style: isHint
                      ? TextStyle(color: theme.appColors.secondaryText)
                      : null,
                ),
              ),
            ),
          ),
        ),
        if (hasClear)
          IconButton(
            key: clearKey,
            icon: const Icon(Icons.clear, size: 16),
            tooltip: clearTooltip,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onClear,
          ),
      ],
    );
  }
}

/// The validation message, announced to screen readers when it appears.
class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Text(
          message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

class _TimezoneDropdown extends StatelessWidget {
  final int index;
  final String timezone;
  final ValueChanged<String> onChanged;

  const _TimezoneDropdown({
    required this.index,
    required this.timezone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      key: Key('slotTimezone_$index'),
      initialValue: normalizeTimezone(timezone),
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
        if (zone != null) onChanged(zone);
      },
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime? b) =>
    b != null && a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _clamp(DateTime d, DateTime lo, DateTime hi) =>
    d.isBefore(lo) ? lo : (d.isAfter(hi) ? hi : d);

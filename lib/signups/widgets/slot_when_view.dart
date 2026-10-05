import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_format.dart';

/// A slot's date and time range (see [formatSlotWhen]): the date on one line
/// and, when the slot has times on one day, the time range under it. Shows
/// nothing for a slot with no schedule. Wraps within the width it is given,
/// so with [showIcon] it needs a bounded width (as in a card or table cell).
class SlotWhenView extends StatelessWidget {
  final SignupSlot slot;

  /// Put a calendar icon before the text, as on the slot cards.
  final bool showIcon;

  /// The text style; defaults to small secondary text.
  final TextStyle? style;

  const SlotWhenView({
    super.key,
    required this.slot,
    this.showIcon = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final when = formatSlotWhen(slot);
    if (when == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textStyle =
        style ??
        theme.textTheme.bodySmall?.copyWith(
          color: theme.appColors.secondaryText,
        );
    final lines = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(when.primary, style: textStyle),
        if (when.secondary != null) Text(when.secondary!, style: textStyle),
      ],
    );
    if (!showIcon) return lines;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          // Lines the icon up with the first line of text.
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.calendar_today,
            size: 14,
            color: theme.appColors.secondaryText,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(child: lines),
      ],
    );
  }
}

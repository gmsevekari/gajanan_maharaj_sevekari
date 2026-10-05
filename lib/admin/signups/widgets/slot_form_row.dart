import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/slot_schedule_field.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_schedule.dart';

/// One editable slot row inside [AdminCreateSignupScreen]'s dynamic
/// slot list builder. The text fields live in caller-owned controllers and
/// the schedule in a [SlotScheduleField], so the parent's single [Form]
/// validates this row's fields along with everything else on the screen.
class SlotFormRow extends StatelessWidget {
  final int index;
  final TextEditingController labelEnController;
  final TextEditingController labelMrController;
  final TextEditingController capacityController;
  final TextEditingController suggestedAmountController;

  /// The schedule the row starts with; the row owns it from then on and
  /// reports every change through [onScheduleChanged].
  final SlotScheduleInput schedule;
  final ValueChanged<SlotScheduleInput> onScheduleChanged;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const SlotFormRow({
    super.key,
    required this.index,
    required this.labelEnController,
    required this.labelMrController,
    required this.capacityController,
    required this.suggestedAmountController,
    required this.schedule,
    required this.onScheduleChanged,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, l10n),
            _buildLabelFields(l10n),
            const SizedBox(height: 12),
            _buildCapacityField(l10n),
            const SizedBox(height: 12),
            _buildSuggestedAmountField(l10n),
            const SizedBox(height: 12),
            SlotScheduleField(
              index: index,
              initialValue: schedule,
              dateRequiredMessage: l10n.signupSlotDateRequired,
              endNotAfterStartMessage: l10n.signupSlotEndBeforeStartError,
              onChanged: onScheduleChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${l10n.signupSlotHeading} ${index + 1}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_upward),
          tooltip: l10n.signupMoveSlotUpTooltip,
          onPressed: onMoveUp,
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward),
          tooltip: l10n.signupMoveSlotDownTooltip,
          onPressed: onMoveDown,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.signupRemoveSlotTooltip,
          onPressed: onRemove,
        ),
      ],
    );
  }

  Widget _buildLabelFields(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: Key('slotLabelEn_$index'),
          controller: labelEnController,
          decoration: InputDecoration(
            labelText: l10n.signupSlotLabelEnLabel,
            border: const OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? l10n.signupSlotLabelEnRequired
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: Key('slotLabelMr_$index'),
          controller: labelMrController,
          decoration: InputDecoration(
            labelText: l10n.signupSlotLabelMrLabel,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityField(AppLocalizations l10n) {
    return TextFormField(
      key: Key('slotCapacity_$index'),
      controller: capacityController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: l10n.signupSlotCapacityLabel,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.signupSlotCapacityRequired;
        }
        final capacity = int.tryParse(value.trim());
        return capacity == null || capacity <= 0
            ? l10n.signupSlotCapacityInvalid
            : null;
      },
    );
  }

  Widget _buildSuggestedAmountField(AppLocalizations l10n) {
    return TextFormField(
      key: Key('slotSuggestedAmount_$index'),
      controller: suggestedAmountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: l10n.signupSlotSuggestedAmountLabel,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        final amount = double.tryParse(value.trim());
        return amount == null || amount < 0
            ? l10n.signupSlotSuggestedAmountInvalid
            : null;
      },
    );
  }
}

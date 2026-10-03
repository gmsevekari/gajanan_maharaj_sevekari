import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// One editable slot row inside [AdminCreateSignupScreen]'s dynamic
/// slot list builder. Purely presentational — all state lives in the
/// caller-owned controllers, so the parent's single [Form] validates this
/// row's fields along with everything else on the screen.
class SlotFormRow extends StatelessWidget {
  final int index;
  final TextEditingController labelEnController;
  final TextEditingController labelMrController;
  final TextEditingController capacityController;
  final TextEditingController suggestedAmountController;
  final DateTime? date;
  final ValueChanged<DateTime> onDateChanged;
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
    required this.date,
    required this.onDateChanged,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  /// How far into the future an admin can schedule a slot. A fixed offset
  /// from "now" rather than a hardcoded calendar year, so this doesn't need
  /// bumping as real years pass.
  static const Duration _maxSlotDateHorizon = Duration(days: 365 * 5);

  Future<void> _pickDate(
    BuildContext context,
    FormFieldState<DateTime> field,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(_maxSlotDateHorizon),
    );
    if (picked != null) {
      field.didChange(picked);
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${localizations.signupSlotHeading} ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: localizations.signupMoveSlotUpTooltip,
                  onPressed: onMoveUp,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  tooltip: localizations.signupMoveSlotDownTooltip,
                  onPressed: onMoveDown,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: localizations.signupRemoveSlotTooltip,
                  onPressed: onRemove,
                ),
              ],
            ),
            TextFormField(
              key: Key('slotLabelEn_$index'),
              controller: labelEnController,
              decoration: InputDecoration(
                labelText: localizations.signupSlotLabelEnLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return localizations.signupSlotLabelEnRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('slotLabelMr_$index'),
              controller: labelMrController,
              decoration: InputDecoration(
                labelText: localizations.signupSlotLabelMrLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('slotCapacity_$index'),
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localizations.signupSlotCapacityLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return localizations.signupSlotCapacityRequired;
                }
                final capacity = int.tryParse(value.trim());
                if (capacity == null || capacity <= 0) {
                  return localizations.signupSlotCapacityInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('slotSuggestedAmount_$index'),
              controller: suggestedAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: localizations.signupSlotSuggestedAmountLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null;
                }
                final amount = double.tryParse(value.trim());
                if (amount == null || amount < 0) {
                  return localizations.signupSlotSuggestedAmountInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            FormField<DateTime>(
              initialValue: date,
              // Validates the field's own value, which _pickDate keeps in
              // step with [date], so the error clears the moment a date is
              // picked rather than at the next Save.
              validator: (value) =>
                  value == null ? localizations.signupSlotDateRequired : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          date != null
                              ? DateFormat('yyyy-MM-dd').format(date!)
                              : localizations.signupSlotNoDateLabel,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _pickDate(context, field),
                        child: Text(localizations.signupSlotSetDateLabel),
                      ),
                    ],
                  ),
                  if (field.hasError)
                    Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

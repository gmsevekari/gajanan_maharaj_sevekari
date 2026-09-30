import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// One editable slot row inside [AdminCreateSignupSheetScreen]'s dynamic
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
  final ValueChanged<DateTime?> onDateChanged;
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

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
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
                    '${localizations.signupSheetSlotHeading} ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: localizations.signupSheetMoveSlotUpTooltip,
                  onPressed: onMoveUp,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  tooltip: localizations.signupSheetMoveSlotDownTooltip,
                  onPressed: onMoveDown,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: localizations.signupSheetRemoveSlotTooltip,
                  onPressed: onRemove,
                ),
              ],
            ),
            TextFormField(
              key: Key('slotLabelEn_$index'),
              controller: labelEnController,
              decoration: InputDecoration(
                labelText: localizations.signupSheetSlotLabelEnLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return localizations.signupSheetSlotLabelEnRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('slotLabelMr_$index'),
              controller: labelMrController,
              decoration: InputDecoration(
                labelText: localizations.signupSheetSlotLabelMrLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return localizations.signupSheetSlotLabelMrRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('slotCapacity_$index'),
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localizations.signupSheetSlotCapacityLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return localizations.signupSheetSlotCapacityRequired;
                }
                final capacity = int.tryParse(value.trim());
                if (capacity == null || capacity <= 0) {
                  return localizations.signupSheetSlotCapacityInvalid;
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
                labelText: localizations.signupSheetSlotSuggestedAmountLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('yyyy-MM-dd').format(date!)
                        : localizations.signupSheetSlotNoDateLabel,
                  ),
                ),
                TextButton(
                  onPressed: () => _pickDate(context),
                  child: Text(localizations.signupSheetSlotSetDateLabel),
                ),
                if (date != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => onDateChanged(null),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

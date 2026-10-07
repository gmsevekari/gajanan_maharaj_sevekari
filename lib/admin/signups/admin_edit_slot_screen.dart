import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/slot_form_row.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/entry_validators.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:gajanan_maharaj_sevekari/utils/form_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_schedule.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';
import 'package:gajanan_maharaj_sevekari/widgets/fitted_app_bar_title.dart';

/// An admin changing an existing slot: its labels, capacity, suggested
/// amount, dates and times, and timezone. Reached from the Edit button on
/// [AdminSlotCard]; closes with `true` once the changes are saved.
///
/// Who has signed up is untouched: the slot keeps its entries and its
/// claimed count, and the capacity can't go below that count.
class AdminEditSlotScreen extends StatefulWidget {
  final String signupId;
  final SignupSlot slot;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const AdminEditSlotScreen({
    super.key,
    required this.signupId,
    required this.slot,
    this.firestore,
    this.signupService,
  });

  @override
  State<AdminEditSlotScreen> createState() => _AdminEditSlotScreenState();
}

class _AdminEditSlotScreenState extends State<AdminEditSlotScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SignupService _service;
  late final TextEditingController _labelEn;
  late final TextEditingController _labelMr;
  late final TextEditingController _capacity;
  late final TextEditingController _amount;
  late final SlotScheduleInput _initialSchedule;
  late SlotScheduleInput _schedule;

  bool _saving = false;
  bool _dirty = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    final slot = widget.slot;
    _labelEn = TextEditingController(text: slot.labelEn);
    _labelMr = TextEditingController(text: slot.labelMr);
    _capacity = TextEditingController(text: slot.capacity.toString());
    _amount = TextEditingController(
      text: slot.suggestedAmount == null
          ? ''
          : formatPledgeAmount(slot.suggestedAmount!),
    );
    _initialSchedule = slotScheduleInputFromInstants(
      startAt: slot.startAt,
      endAt: slot.endAt,
      timezone: slot.timezone,
    );
    _schedule = _initialSchedule;
    for (final controller in [_labelEn, _labelMr, _capacity, _amount]) {
      controller.addListener(_refreshDirty);
    }
  }

  @override
  void dispose() {
    _labelEn.dispose();
    _labelMr.dispose();
    _capacity.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// Whether anything differs from the slot as it was opened. Changing a
  /// field back to what it was clears this again.
  bool get _hasChanges {
    final slot = widget.slot;
    final amount = slot.suggestedAmount;
    return _labelEn.text != slot.labelEn ||
        _labelMr.text != slot.labelMr ||
        _capacity.text != slot.capacity.toString() ||
        _amount.text != (amount == null ? '' : formatPledgeAmount(amount)) ||
        _schedule != _initialSchedule;
  }

  void _refreshDirty() {
    final dirty = _hasChanges;
    if (dirty != _dirty) setState(() => _dirty = dirty);
  }

  void _onScheduleChanged(SlotScheduleInput schedule) {
    _schedule = schedule;
    _refreshDirty();
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      revealFirstInvalidField(_formKey.currentContext);
      return;
    }
    final schedule = resolveSlotSchedule(_schedule);
    if (schedule is! SlotScheduleResolved) return;

    final slot = widget.slot;
    final amountText = _amount.text.trim();
    final updated = SignupSlot(
      id: slot.id,
      labelEn: _labelEn.text.trim(),
      labelMr: _labelMr.text.trim(),
      startAt: schedule.startAt,
      endAt: schedule.endAt,
      timezone: normalizeTimezone(_schedule.timezone),
      capacity: int.parse(_capacity.text.trim()),
      claimedCount: slot.claimedCount,
      suggestedAmount: amountText.isEmpty ? null : double.tryParse(amountText),
      sortOrder: slot.sortOrder,
      createdAt: slot.createdAt,
    );

    setState(() {
      _saving = true;
      _errorText = null;
    });
    String? error;
    try {
      await _service.updateSlot(widget.signupId, updated);
    } on SlotCapacityBelowClaimedException catch (e) {
      error = l10n.signupSlotCapacityBelowClaimed(e.claimedCount.toString());
    } on Exception catch (e) {
      debugPrint('AdminEditSlotScreen save failed: $e');
      error = l10n.signupSlotUpdateError;
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _errorText = error;
    });
  }

  Future<void> _confirmDiscard(AppLocalizations l10n) async {
    final discard = await showEnglishDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signupDiscardChangesTitle),
        content: Text(l10n.signupDiscardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.signupKeepEditingButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.discardLabel,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      // Leaving with unsaved changes asks first; so does leaving mid-save,
      // which just waits.
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _saving) return;
        _confirmDiscard(l10n);
      },
      child: Scaffold(
        appBar: AppBar(title: FittedAppBarTitle(l10n.signupEditSlotTitle)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SlotFormRow(
                  index: 0,
                  showHeader: false,
                  labelEnController: _labelEn,
                  labelMrController: _labelMr,
                  capacityController: _capacity,
                  suggestedAmountController: _amount,
                  minCapacity: widget.slot.claimedCount,
                  schedule: _schedule,
                  onScheduleChanged: _onScheduleChanged,
                ),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _errorText!,
                        style: TextStyle(color: theme.appColors.error),
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _saving ? null : () => _save(l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.signupSaveButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

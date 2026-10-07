import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/slot_form_row.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/unsaved_changes_guard.dart';
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

/// An admin changing an existing slot - or, with [AdminEditSlotScreen.add],
/// adding a new one: its labels, capacity, suggested amount, dates and times,
/// and timezone. Reached from the Slots page; closes with `true` once the
/// changes are saved.
///
/// Editing leaves who has signed up untouched: the slot keeps its entries and
/// its claimed count, and the capacity can't go below that count.
class AdminEditSlotScreen extends StatefulWidget {
  final String signupId;

  /// The slot being edited; null when adding one.
  final SignupSlot? slot;

  /// Where a new slot goes in the order: after every existing slot.
  final int nextSortOrder;

  /// The timezone a new slot starts in (the group's default zone).
  final String defaultTimezone;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const AdminEditSlotScreen({
    super.key,
    required this.signupId,
    required SignupSlot this.slot,
    this.firestore,
    this.signupService,
  }) : nextSortOrder = 0,
       defaultTimezone = EventTimezone.defaultZone;

  const AdminEditSlotScreen.add({
    super.key,
    required this.signupId,
    required this.nextSortOrder,
    required this.defaultTimezone,
    this.firestore,
    this.signupService,
  }) : slot = null;

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

  /// What the fields held when the screen opened, to tell if anything changed.
  late final ({String labelEn, String labelMr, String capacity, String amount})
  _initial;

  bool get _isNew => widget.slot == null;

  bool _saving = false;
  bool _dirty = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    final slot = widget.slot;
    _initial = (
      labelEn: slot?.labelEn ?? '',
      labelMr: slot?.labelMr ?? '',
      capacity: slot == null ? '' : slot.capacity.toString(),
      amount: slot?.suggestedAmount == null
          ? ''
          : formatPledgeAmount(slot!.suggestedAmount!),
    );
    _labelEn = TextEditingController(text: _initial.labelEn);
    _labelMr = TextEditingController(text: _initial.labelMr);
    _capacity = TextEditingController(text: _initial.capacity);
    _amount = TextEditingController(text: _initial.amount);
    _initialSchedule = slot == null
        ? SlotScheduleInput(timezone: normalizeTimezone(widget.defaultTimezone))
        : slotScheduleInputFromInstants(
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

  /// Whether anything differs from the screen as it was opened. Changing a
  /// field back to what it was clears this again.
  bool get _hasChanges =>
      _labelEn.text != _initial.labelEn ||
      _labelMr.text != _initial.labelMr ||
      _capacity.text != _initial.capacity ||
      _amount.text != _initial.amount ||
      _schedule != _initialSchedule;

  /// Called when anything is edited: refreshes whether there are unsaved
  /// changes, and drops the message from a failed save, which no longer
  /// describes what is on screen.
  void _refreshDirty() {
    final dirty = _hasChanges;
    if (dirty != _dirty || _errorText != null) {
      setState(() {
        _dirty = dirty;
        _errorText = null;
      });
    }
  }

  void _onScheduleChanged(SlotScheduleInput schedule) {
    _schedule = schedule;
    _refreshDirty();
  }

  /// The slot as filled in: the edited slot, or a new one at the end of the
  /// order with nobody signed up. When editing, a schedule the admin didn't
  /// touch keeps the saved instants and timezone exactly: reading them into
  /// the form and back drops seconds and rewrites a timezone the app doesn't
  /// know.
  SignupSlot? _filledInSlot() {
    final slot = widget.slot;
    DateTime? startAt;
    DateTime? endAt;
    var timezone = normalizeTimezone(_schedule.timezone);
    if (slot != null && _schedule == _initialSchedule && slot.hasSchedule) {
      startAt = slot.startAt;
      endAt = slot.endAt;
      timezone = slot.timezone;
    } else {
      final schedule = resolveSlotSchedule(_schedule);
      if (schedule is! SlotScheduleResolved) return null;
      startAt = schedule.startAt;
      endAt = schedule.endAt;
    }
    final amountText = _amount.text.trim();
    return SignupSlot(
      id: slot?.id,
      labelEn: _labelEn.text.trim(),
      labelMr: _labelMr.text.trim(),
      startAt: startAt,
      endAt: endAt,
      timezone: timezone,
      capacity: int.parse(_capacity.text.trim()),
      claimedCount: slot?.claimedCount ?? 0,
      suggestedAmount: amountText.isEmpty ? null : double.tryParse(amountText),
      sortOrder: slot?.sortOrder ?? widget.nextSortOrder,
      createdAt: slot?.createdAt ?? DateTime.now(),
    );
  }

  /// Writes [slot]. Returns the message to show if it couldn't be saved, or
  /// null once it is.
  Future<String?> _persist(SignupSlot slot, AppLocalizations l10n) async {
    try {
      if (_isNew) {
        await _service.addSlot(widget.signupId, slot);
      } else {
        await _service.updateSlot(widget.signupId, slot);
      }
      return null;
    } on SlotCapacityBelowClaimedException catch (e) {
      return l10n.signupSlotCapacityBelowClaimed(e.claimedCount.toString());
    } on Exception catch (e) {
      debugPrint('AdminEditSlotScreen save failed: $e');
      return _isNew ? l10n.signupSlotAddError : l10n.signupSlotUpdateError;
    }
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_saving) return;
    final existing = widget.slot;
    if (existing != null && existing.hasSchedule && !_hasChanges) {
      // Nothing to write; closing without `true` means no confirmation. (A
      // slot with no schedule still has to be given one.)
      Navigator.pop(context, false);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      revealFirstInvalidField(_formKey.currentContext);
      return;
    }
    final filledIn = _filledInSlot();
    if (filledIn == null) return;

    setState(() {
      _saving = true;
      _errorText = null;
    });
    String? error;
    var finished = false;
    try {
      error = await _persist(filledIn, l10n);
      finished = true;
    } finally {
      // Also runs when an Error escapes, so the screen is never left
      // spinning behind a button that can't be pressed.
      if (mounted && (!finished || error != null)) {
        setState(() {
          _saving = false;
          _errorText = error;
        });
      }
    }
    if (error == null && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return UnsavedChangesGuard(
      hasUnsavedChanges: _dirty,
      busy: _saving,
      child: Scaffold(
        appBar: AppBar(
          title: FittedAppBarTitle(
            _isNew ? l10n.signupAddSlotButton : l10n.signupEditSlotTitle,
          ),
        ),
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
                  minCapacity: widget.slot?.claimedCount,
                  schedule: _schedule,
                  onScheduleChanged: _onScheduleChanged,
                ),
                if (_errorText != null) _buildError(context),
                _buildSaveButton(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      liveRegion: true,
      child: Text(
        _errorText!,
        style: TextStyle(color: Theme.of(context).appColors.error),
      ),
    ),
  );

  Widget _buildSaveButton(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return ElevatedButton(
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
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_edit_slot_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_entry_actions.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_slot_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_signup_tabbed_scaffold.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/default_timezone.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// Every slot on a sign-up with how full it is and Delete, Edit and "Add
/// Devotee" actions, plus an Add Slot button, reached from
/// [AdminSignupDetailScreen]'s "Slots" card. Splits slots into
/// Upcoming/Past by their own date - a slot with no date counts as upcoming,
/// since there's no basis to call it past. Who has signed up is listed on
/// [AdminSignupEntriesScreen].
class AdminSignupSlotsScreen extends StatefulWidget {
  final String signupId;
  final Signup signup;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const AdminSignupSlotsScreen({
    super.key,
    required this.signupId,
    required this.signup,
    this.firestore,
    this.signupService,
  });

  @override
  State<AdminSignupSlotsScreen> createState() => _AdminSignupSlotsScreenState();
}

class _AdminSignupSlotsScreenState extends State<AdminSignupSlotsScreen>
    with SingleTickerProviderStateMixin {
  /// Room under the last card for the floating Add Slot button (56 high, 16
  /// above the bottom), before any system inset.
  static const double _fabClearance = 88;

  late final SignupService _service;
  late final AdminEntryActions _actions;
  late final TabController _tabController;
  late final Stream<List<SignupSlot>> _slotsStream;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    _actions = AdminEntryActions(_service);
    _tabController = TabController(length: 2, vsync: this);
    _slotsStream = _service.getSlots(widget.signupId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _editSlot(SignupSlot slot) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditSlotScreen(
          signupId: widget.signupId,
          slot: slot,
          signupService: _service,
        ),
      ),
    );
    if (saved != true || !mounted) return;
    _snack(l10n.signupSlotUpdateSuccess);
  }

  /// Adds a slot after all the existing ones (past or upcoming), in the zone
  /// of the last one - or the group's default zone, for the first slot or
  /// when the last one's zone isn't one the app knows.
  Future<void> _addSlot(List<SignupSlot> slots) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final ordered = [...slots]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final nextSortOrder = ordered.isEmpty ? 0 : ordered.last.sortOrder + 1;
    final lastZone = ordered.isEmpty ? null : ordered.last.timezone;
    final timezone = EventTimezone.supported.contains(lastZone)
        ? lastZone!
        : defaultTimezoneFor(context, widget.signup.groupId);
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditSlotScreen.add(
          signupId: widget.signupId,
          nextSortOrder: nextSortOrder,
          defaultTimezone: timezone,
          signupService: _service,
        ),
      ),
    );
    if (saved != true || !mounted) return;
    _snack(l10n.signupSlotAddSuccess);
  }

  /// Deletes [slot] after confirming - or explains why it can't be: people
  /// have signed up for it, and deleting it would orphan their entries.
  Future<void> _deleteSlot(SignupSlot slot) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    if (slot.claimedCount > 0) return _explainHasEntries(slot.claimedCount);

    final named = slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr;
    final label = named.isNotEmpty ? named : l10n.signupSlotHeading;
    final confirmed = await showEnglishDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signupDeleteSlotConfirmTitle),
        content: Text(l10n.signupDeleteSlotConfirmMessage(label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.signupDeleteSlotButton,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteSlot(widget.signupId, slot.id!);
      if (mounted) _snack(l10n.signupSlotDeleteSuccess);
    } on SlotHasClaimedEntriesException catch (e) {
      // Someone signed up after this page loaded.
      if (mounted) await _explainHasEntries(e.claimedCount);
    } on Exception catch (e) {
      debugPrint('AdminSignupSlotsScreen delete failed: $e');
      if (mounted) _snack(l10n.signupSlotDeleteError);
    }
  }

  Future<void> _explainHasEntries(int count) {
    final l10n = lookupAppLocalizations(const Locale('en'));
    return showEnglishDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signupSlotHasEntriesTitle),
        content: Text(l10n.signupSlotHasEntriesMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<SignupSlot>>(
      stream: _slotsStream,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final slots = snapshot.data ?? const <SignupSlot>[];
        // By date, as on the Entries page, so a slot added later still lands
        // where its date puts it.
        final byDate = [...slots]
          ..sort((a, b) {
            final byStart = SignupSlot.compareByStart(a, b);
            // Slots that tie on start and order still need a fixed order.
            return byStart != 0 ? byStart : (a.id ?? '').compareTo(b.id ?? '');
          });
        final now = DateTime.now();
        final upcoming = byDate.where((s) => !s.isPast(now)).toList();
        final past = byDate.where((s) => s.isPast(now)).toList();

        Widget tab(List<SignupSlot> list) => loading
            ? const Center(child: CircularProgressIndicator())
            : _buildSlotList(context, list, l10n);

        return AdminSignupTabbedScaffold(
          title: l10n.signupSlotsHeading,
          controller: _tabController,
          upcoming: tab(upcoming),
          past: tab(past),
          // Not while loading, or when the slots couldn't be loaded: the new
          // slot's place in the order comes from the slots on screen.
          floatingActionButton: loading || snapshot.hasError
              ? null
              : FloatingActionButton.extended(
                  key: const Key('addSlotButton'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.signupAddSlotButton),
                  onPressed: () => _addSlot(slots),
                ),
        );
      },
    );
  }

  Widget _buildSlotList(
    BuildContext context,
    List<SignupSlot> slots,
    AppLocalizations l10n,
  ) {
    if (slots.isEmpty) {
      return Center(
        child: Text(
          l10n.signupNoSlotsInTabMessage,
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView(
      // Room under the last card for the floating Add Slot button.
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        _fabClearance + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        for (final slot in slots)
          AdminSlotCard(
            slot: slot,
            onAddEntry: (s) =>
                _actions.showAddDialog(context, widget.signup, s),
            onEdit: _editSlot,
            onDelete: _deleteSlot,
          ),
      ],
    );
  }
}

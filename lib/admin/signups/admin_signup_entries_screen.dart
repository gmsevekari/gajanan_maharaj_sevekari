import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_entry_actions.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_signup_tabbed_scaffold.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_slot_entries_card.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// Every devotee's entry on a sign-up, grouped under its slot, with edit,
/// remove and contact actions. Reached from [AdminSignupDetailScreen]'s
/// "Entries" card. Splits entries into Upcoming/Past by their slot's date,
/// like the devotee Entries screen - a slot with no date counts as upcoming.
class AdminSignupEntriesScreen extends StatefulWidget {
  final String signupId;
  final Signup signup;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const AdminSignupEntriesScreen({
    super.key,
    required this.signupId,
    required this.signup,
    this.firestore,
    this.signupService,
  });

  @override
  State<AdminSignupEntriesScreen> createState() =>
      _AdminSignupEntriesScreenState();
}

class _AdminSignupEntriesScreenState extends State<AdminSignupEntriesScreen>
    with SingleTickerProviderStateMixin {
  late final SignupService _service;
  late final AdminEntryActions _actions;
  late final TabController _tabController;
  late final Stream<List<SignupSlot>> _slotsStream;
  late final Stream<List<SignupEntry>> _entriesStream;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    _actions = AdminEntryActions(_service);
    _tabController = TabController(length: 2, vsync: this);
    _slotsStream = _service.getSlots(widget.signupId);
    _entriesStream = _service.getAllEntries(widget.signupId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  /// Date first (undated last), then the slots' own order.
  static int _compareSlots(SignupSlot a, SignupSlot b) {
    final dateA = a.date;
    final dateB = b.date;
    if (dateA == null && dateB != null) return 1;
    if (dateA != null && dateB == null) return -1;
    if (dateA != null && dateB != null) {
      final byDate = dateA.compareTo(dateB);
      if (byDate != 0) return byDate;
    }
    return a.sortOrder.compareTo(b.sortOrder);
  }

  Widget _buildScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<SignupSlot>>(
      stream: _slotsStream,
      builder: (context, slotsSnapshot) {
        final slots = (slotsSnapshot.data ?? const <SignupSlot>[]).toList()
          ..sort(_compareSlots);

        return StreamBuilder<List<SignupEntry>>(
          stream: _entriesStream,
          builder: (context, entriesSnapshot) {
            final loading =
                entriesSnapshot.connectionState == ConnectionState.waiting;
            final entries = entriesSnapshot.data ?? const <SignupEntry>[];
            final now = DateTime.now();

            // One group per slot that has entries, in slot order.
            final upcoming = <(SignupSlot, List<SignupEntry>)>[];
            final past = <(SignupSlot, List<SignupEntry>)>[];
            for (final slot in slots) {
              final slotEntries = entries
                  .where((e) => e.slotId == slot.id)
                  .toList();
              if (slotEntries.isEmpty) continue;
              final isPast = slot.date?.isBefore(now) ?? false;
              (isPast ? past : upcoming).add((slot, slotEntries));
            }

            Widget tab(List<(SignupSlot, List<SignupEntry>)> groups) => loading
                ? const Center(child: CircularProgressIndicator())
                : _buildGroups(context, groups, l10n);

            return AdminSignupTabbedScaffold(
              title: l10n.signupEntriesHeading,
              controller: _tabController,
              upcoming: tab(upcoming),
              past: tab(past),
            );
          },
        );
      },
    );
  }

  Widget _buildGroups(
    BuildContext context,
    List<(SignupSlot, List<SignupEntry>)> groups,
    AppLocalizations l10n,
  ) {
    if (groups.isEmpty) {
      return Center(
        child: Text(
          l10n.signupEntriesEmptyMessage,
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final (slot, slotEntries) in groups)
          AdminSlotEntriesCard(
            slot: slot,
            entries: slotEntries,
            onEditEntry: (e) =>
                _actions.showEditDialog(context, widget.signup, e),
            onRemoveEntry: (e) =>
                _actions.confirmRemove(context, widget.signup, e),
          ),
      ],
    );
  }
}

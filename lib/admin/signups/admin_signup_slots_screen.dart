import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_entry_actions.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_slot_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_signup_tabbed_scaffold.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// Every slot on a sign-up with how full it is and an "Add Devotee" action,
/// reached from [AdminSignupDetailScreen]'s "Slots" card. Splits slots into
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

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<SignupSlot>>(
      stream: _slotsStream,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final slots = snapshot.data ?? const <SignupSlot>[];
        final now = DateTime.now();
        final upcoming = slots.where((s) => !s.isPast(now)).toList();
        final past = slots.where((s) => s.isPast(now)).toList();

        Widget tab(List<SignupSlot> list) => loading
            ? const Center(child: CircularProgressIndicator())
            : _buildSlotList(context, list, l10n);

        return AdminSignupTabbedScaffold(
          title: l10n.signupSlotsHeading,
          controller: _tabController,
          upcoming: tab(upcoming),
          past: tab(past),
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
      padding: const EdgeInsets.all(16),
      children: [
        for (final slot in slots)
          AdminSlotCard(
            slot: slot,
            onAddEntry: (s) =>
                _actions.showAddDialog(context, widget.signup, s),
          ),
      ],
    );
  }
}

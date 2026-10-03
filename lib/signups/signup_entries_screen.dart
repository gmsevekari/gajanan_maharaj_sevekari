import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_entries_table.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

/// Every devotee's entries on a sign-up, reached from
/// [SignupDetailScreen]'s "Entries" card. Splits entries into Upcoming/Past
/// by their slot's date, like [MySignupsScreen] - an entry whose slot has no
/// date (or is gone) is treated as upcoming, since there's no basis to call
/// it past.
class SignupEntriesScreen extends StatefulWidget {
  final String signupId;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const SignupEntriesScreen({
    super.key,
    required this.signupId,
    this.firestore,
    this.signupService,
  });

  @override
  State<SignupEntriesScreen> createState() => _SignupEntriesScreenState();
}

class _SignupEntriesScreenState extends State<SignupEntriesScreen>
    with SingleTickerProviderStateMixin {
  late final SignupService _service;
  late final TabController _tabController;
  late final Stream<List<SignupEntry>> _entriesStream;
  late final Stream<List<SignupSlot>> _slotsStream;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    _tabController = TabController(length: 2, vsync: this);
    _entriesStream = _service.getAllEntries(widget.signupId);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signupEntriesHeading),
        bottom: TabBar(
          controller: _tabController,
          // The default label colour is the theme's primary, which is the
          // app bar's own colour, so the selected tab's name is invisible.
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withValues(
            alpha: 0.7,
          ),
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: [
            Tab(text: l10n.signupUpcomingTab),
            Tab(text: l10n.signupPastTab),
          ],
        ),
        actions: [
          IconButton(
            icon: const ThemedIcon(LogicalIcon.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
          IconButton(
            icon: const ThemedIcon(LogicalIcon.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: StreamBuilder<List<SignupSlot>>(
        stream: _slotsStream,
        builder: (context, slotsSnapshot) {
          final slots = slotsSnapshot.data ?? const [];

          return StreamBuilder<List<SignupEntry>>(
            stream: _entriesStream,
            builder: (context, entriesSnapshot) {
              if (entriesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final entries = entriesSnapshot.data ?? const [];
              final now = DateTime.now();
              final upcoming = <SignupEntry>[];
              final past = <SignupEntry>[];
              for (final entry in entries) {
                final slot = slots
                    .where((s) => s.id == entry.slotId)
                    .firstOrNull;
                if (slot?.date != null && slot!.date!.isBefore(now)) {
                  past.add(entry);
                } else {
                  upcoming.add(entry);
                }
              }

              return TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _tabController,
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SignupEntriesTable(entries: upcoming, slots: slots),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [SignupEntriesTable(entries: past, slots: slots)],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

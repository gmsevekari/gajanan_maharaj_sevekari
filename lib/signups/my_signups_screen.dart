import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/my_signups_section.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

/// The devotee's own claimed entries on a sign-up sheet, reached from
/// [SignupSheetDetailScreen]'s "My Sign Ups" card. Splits entries into
/// Upcoming/Past by their slot's date, matching [SignupSlotsScreen]'s own
/// split - an entry whose slot has no date is treated as upcoming, since
/// there's no basis to call it past.
class MySignupsScreen extends StatefulWidget {
  final String sheetId;
  final String deviceId;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const MySignupsScreen({
    super.key,
    required this.sheetId,
    required this.deviceId,
    this.firestore,
    this.signupService,
  });

  @override
  State<MySignupsScreen> createState() => _MySignupsScreenState();
}

class _MySignupsScreenState extends State<MySignupsScreen>
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
    _entriesStream = _service.getEntriesByDevice(
      widget.sheetId,
      widget.deviceId,
    );
    _slotsStream = _service.getSlots(widget.sheetId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmCancelEntry(SignupEntry entry, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signupCancelSignupConfirmTitle),
        content: Text(l10n.signupCancelSignupConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _cancelEntry(entry, l10n);
            },
            child: Text(
              l10n.yes,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelEntry(SignupEntry entry, AppLocalizations l10n) async {
    try {
      await _service.cancelEntry(widget.sheetId, entry.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupCancelSignupSuccess)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupCancelSignupError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signupMySignupsHeading),
        bottom: TabBar(
          controller: _tabController,
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
                controller: _tabController,
                children: [
                  MySignupsSection(
                    entries: upcoming,
                    slots: slots,
                    onCancelEntry: (entry) => _confirmCancelEntry(entry, l10n),
                    emptyMessage: l10n.signupNoMySignups,
                  ),
                  MySignupsSection(
                    entries: past,
                    slots: slots,
                    // No Cancel button on this tab, so this is never called.
                    onCancelEntry: (_) {},
                    showCancelButton: false,
                    emptyMessage: l10n.signupNoMySignups,
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

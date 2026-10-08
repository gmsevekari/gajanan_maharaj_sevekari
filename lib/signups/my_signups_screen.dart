import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/widgets/fitted_app_bar_title.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry_details.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/notifications/signup_reminder_permission_hint.dart';
import 'package:gajanan_maharaj_sevekari/notifications/signup_reminder_subscriptions.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/claim_my_signup_dialog.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/my_signups_section.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_entry_edit_dialog.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/phone_number_field.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// The devotee's own claimed entries on a sign-up signup, reached from
/// [SignupDetailScreen]'s "My Sign Ups" card. Splits entries into
/// Upcoming/Past by their slot's date, matching [SignupSlotsScreen]'s own
/// split - an entry whose slot has no date is treated as upcoming, since
/// there's no basis to call it past. Upcoming entries can be edited
/// (name, phone, email, pledge, note) or cancelled. "Claim My Sign Up" links
/// entries made with a phone number (by an admin, or on another device) to
/// this device.
class MySignupsScreen extends StatefulWidget {
  final String signupId;
  final String deviceId;

  /// The sign-up's group, used for the country code a new phone number
  /// starts with when editing an entry.
  final String? groupId;

  /// Whether claiming entries needs the sign-up's join code.
  final bool requiresJoinCode;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  /// Injected for testing; keeps this device's reminder subscriptions in line
  /// with its entries after a claim or a cancellation.
  @visibleForTesting
  final SignupReminderSubscriptions? reminders;

  /// Injected for testing; nudges the devotee to allow notifications, once,
  /// after they claim their sign-up.
  @visibleForTesting
  final SignupReminderPermissionHint reminderHint;

  const MySignupsScreen({
    super.key,
    required this.signupId,
    required this.deviceId,
    this.groupId,
    this.requiresJoinCode = false,
    this.firestore,
    this.signupService,
    this.reminders,
    this.reminderHint = const SignupReminderPermissionHint(),
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
  late final SignupReminderSubscriptions _reminders;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    _tabController = TabController(length: 2, vsync: this);
    _entriesStream = _service.getEntriesByDevice(
      widget.signupId,
      widget.deviceId,
    );
    _slotsStream = _service.getSlots(widget.signupId);
    _reminders =
        widget.reminders ??
        SignupReminderSubscriptions(
          signupService: _service,
          deviceId: () async => widget.deviceId,
        );
    // Opening the sign-ups is a chance to catch up on what changed elsewhere:
    // an admin removing an entry or giving a slot its date.
    unawaited(_syncReminders());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmCancelEntry(SignupEntry entry, AppLocalizations l10n) {
    showEnglishDialog(
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

  Future<void> _claimMine(AppLocalizations l10n) async {
    final claimed = await showEnglishDialog<bool>(
      context: context,
      builder: (_) => ClaimMySignupDialog(
        signupId: widget.signupId,
        deviceId: widget.deviceId,
        requiresJoinCode: widget.requiresJoinCode,
        signupService: _service,
        defaultCountryCode: defaultCountryCodeFor(context, widget.groupId),
      ),
    );
    if (claimed != true) return;
    unawaited(_syncReminders());
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.signupClaimMySignupSuccess)));
    unawaited(widget.reminderHint.showIfNeeded(context, l10n));
  }

  void _editEntry(SignupEntry entry, AppLocalizations l10n) {
    showEnglishDialog(
      context: context,
      builder: (_) => SignupEntryEditDialog(
        entry: entry,
        showContactActions: false,
        requirePhone: true,
        defaultCountryCode: defaultCountryCodeFor(context, widget.groupId),
        onSave: (details) => _saveEntry(entry, details, l10n),
      ),
    );
  }

  /// Saves the edit. Returns null on success (and says so in a snackbar), or
  /// the message for the dialog to show so the devotee can fix the input.
  Future<String?> _saveEntry(
    SignupEntry entry,
    SignupEntryDetails details,
    AppLocalizations l10n,
  ) async {
    try {
      final result = await _service.updateOwnEntry(
        signupId: widget.signupId,
        entryId: entry.id!,
        name: details.name,
        phone: details.phone,
        email: details.email,
        pledgeAmount: details.pledgeAmount,
        note: details.note,
      );
      switch (result['error']) {
        case null:
          if (mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.signupEntryEditSuccess)),
              );
          }
          return null;
        case 'duplicate_entry':
          return l10n.signupDuplicateEntryError;
        default:
          return l10n.signupEntryEditError;
      }
    } catch (error) {
      debugPrint('MySignupsScreen._saveEntry error: $error');
      return l10n.signupEntryEditError;
    }
  }

  /// Brings this device's reminder subscriptions in line with its entries
  /// (on opening, and after a claim or a cancellation). Best effort: the
  /// change already worked, and the next app start tries again.
  Future<void> _syncReminders() async {
    try {
      await _reminders.syncSignup(widget.signupId);
    } on Exception catch (error) {
      debugPrint('MySignupsScreen: reminder sync failed: $error');
    }
  }

  Future<void> _cancelEntry(SignupEntry entry, AppLocalizations l10n) async {
    try {
      await _service.cancelEntry(widget.signupId, entry.id!);
      unawaited(_syncReminders());
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
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: FittedAppBarTitle(l10n.signupMySignupsHeading),
        bottom: TabBar(
          controller: _tabController,
          // The default label colour is the theme's primary, which is the
          // app bar's own colour, so the selected tab's name was invisible.
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('claimMySignupButton'),
                icon: const Icon(Icons.link),
                label: Text(l10n.signupClaimMySignupButton),
                onPressed: () => _claimMine(l10n),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SignupSlot>>(
              stream: _slotsStream,
              builder: (context, slotsSnapshot) {
                final slots = slotsSnapshot.data ?? const [];

                return StreamBuilder<List<SignupEntry>>(
                  stream: _entriesStream,
                  builder: (context, entriesSnapshot) {
                    if (entriesSnapshot.connectionState ==
                        ConnectionState.waiting) {
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
                      if (slot?.isPast(now) ?? false) {
                        past.add(entry);
                      } else {
                        upcoming.add(entry);
                      }
                    }

                    return TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _tabController,
                      children: [
                        MySignupsSection(
                          entries: upcoming,
                          slots: slots,
                          onCancelEntry: (entry) =>
                              _confirmCancelEntry(entry, l10n),
                          onEditEntry: (entry) => _editEntry(entry, l10n),
                          emptyMessage: l10n.signupNoMySignups,
                        ),
                        MySignupsSection(
                          entries: past,
                          slots: slots,
                          emptyMessage: l10n.signupNoMySignups,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

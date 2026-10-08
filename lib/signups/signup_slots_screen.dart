import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/widgets/fitted_app_bar_title.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/notifications/signup_reminder_permission_hint.dart';
import 'package:gajanan_maharaj_sevekari/notifications/signup_reminder_subscriptions.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/claim_slot_dialog.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_slot_tile.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';
import 'package:gajanan_maharaj_sevekari/widgets/phone_number_field.dart';

/// Every slot on a sign-up signup, reached from
/// [SignupDetailScreen]'s "Slots" card. Splits slots into
/// Upcoming/Past by their own date - a slot with no date is treated as
/// upcoming, since there's no basis to call it past. Unlike the signup's
/// Entries table, this screen never shows who's signed up for a slot.
class SignupSlotsScreen extends StatefulWidget {
  final String signupId;
  final Signup signup;
  final String? deviceId;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  /// Injected for testing; keeps this device's reminder subscriptions in line
  /// with its entries after a sign-up.
  @visibleForTesting
  final SignupReminderSubscriptions? reminders;

  /// Injected for testing; nudges the devotee to allow notifications, once,
  /// after they sign up.
  @visibleForTesting
  final SignupReminderPermissionHint reminderHint;

  const SignupSlotsScreen({
    super.key,
    required this.signupId,
    required this.signup,
    required this.deviceId,
    this.firestore,
    this.signupService,
    this.reminders,
    this.reminderHint = const SignupReminderPermissionHint(),
  });

  @override
  State<SignupSlotsScreen> createState() => _SignupSlotsScreenState();
}

class _SignupSlotsScreenState extends State<SignupSlotsScreen>
    with SingleTickerProviderStateMixin {
  late final SignupService _service;
  late final TabController _tabController;
  late final Stream<List<SignupSlot>> _slotsStream;
  late final SignupReminderSubscriptions? _reminders;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    _tabController = TabController(length: 2, vsync: this);
    _slotsStream = _service.getSlots(widget.signupId);
    final deviceId = widget.deviceId;
    _reminders =
        widget.reminders ??
        (deviceId == null
            ? null
            : SignupReminderSubscriptions(
                signupService: _service,
                deviceId: () async => deviceId,
              ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _claimSlot(SignupSlot slot, AppLocalizations l10n) async {
    final claimed = await showEnglishDialog<bool>(
      context: context,
      builder: (_) => ClaimSlotDialog(
        signupId: widget.signupId,
        slot: slot,
        requiresJoinCode: widget.signup.requiresJoinCode,
        deviceId: widget.deviceId,
        signupService: _service,
        defaultCountryCode: defaultCountryCodeFor(
          context,
          widget.signup.groupId,
        ),
      ),
    );

    if (claimed == true) unawaited(_syncReminders());
    if (claimed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.signupClaimSuccess)));
      unawaited(widget.reminderHint.showIfNeeded(context, l10n));
    }
  }

  /// Subscribes this device to reminders for the slot it just signed up for.
  /// Best effort: the sign-up already worked, and the next app start tries
  /// again.
  Future<void> _syncReminders() async {
    try {
      await _reminders?.syncSignup(widget.signupId);
    } on Exception catch (error) {
      debugPrint('SignupSlotsScreen: reminder sync failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: FittedAppBarTitle(l10n.signupSlotsHeading),
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
      body: StreamBuilder<List<SignupSlot>>(
        stream: _slotsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final slots = snapshot.data ?? const [];
          final now = DateTime.now();
          final upcoming = slots.where((s) => !s.isPast(now)).toList();
          final past = slots.where((s) => s.isPast(now)).toList();

          return TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _tabController,
            children: [
              _buildSlotList(upcoming, l10n),
              _buildSlotList(past, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlotList(List<SignupSlot> slots, AppLocalizations l10n) {
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
          SignupSlotTile(
            slot: slot,
            onTap: slot.claimedCount >= slot.capacity
                ? null
                : () => _claimSlot(slot, l10n),
          ),
      ],
    );
  }
}

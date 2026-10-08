import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps this device subscribed to the reminder topic of every upcoming slot
/// it has an entry on, and to nothing else.
///
/// A device is on a slot's topic exactly while an entry on that slot is linked
/// to it (it took the slot, or claimed the entry with "Claim My Sign Up"), the
/// slot has a date and time, and the slot hasn't finished. An entry an admin
/// adds for someone else has no device, so it never subscribes the admin's
/// phone. The app language plays no part: the reminders are always English.
///
/// What is true is read from the server, never the local cache: a stale or
/// empty cached copy must not be taken for "no entries", or reminders would be
/// dropped for someone who still has an entry. If the server can't be reached
/// nothing changes and the next sync tries again.
///
/// What this device is subscribed through is kept in preferences ("wanted":
/// pairs of sign-up and slot ids) so a sign-up that has ended can be let go
/// of. The subscription follows the devotee's "Sign-up reminders" switch:
/// switched off, the wanted slots are remembered but unsubscribed. A topic is
/// put on the "stale" list before it is let go of, and taken off it once the
/// unsubscription worked, so an interrupted or failed one is retried by the
/// next sync instead of being forgotten.
///
/// The public methods run one at a time, across every instance, so two
/// overlapping syncs (a claim and a quick cancel, say) can't overwrite each
/// other's bookkeeping.
class SignupReminderSubscriptions {
  static const String _wantedKey = 'signup_reminder_wanted';
  static const String _staleKey = 'signup_reminder_stale';

  /// The end of the line of queued operations (see [_serialized]).
  static Future<void> _queue = Future<void>.value();

  final SignupService _signupService;
  final Future<String> Function() _deviceId;
  final FirebaseMessaging? _messaging;
  final DateTime Function() _now;
  final Duration _timeout;
  final Duration _readTimeout;

  SignupReminderSubscriptions({
    required SignupService signupService,
    required Future<String> Function() deviceId,
    FirebaseMessaging? messaging,
    DateTime Function()? now,
    Duration timeout = const Duration(seconds: 10),
    Duration readTimeout = const Duration(seconds: 20),
  }) : _signupService = signupService,
       _deviceId = deviceId,
       _messaging = messaging,
       _now = now ?? DateTime.now,
       _timeout = timeout,
       _readTimeout = readTimeout;

  FirebaseMessaging get _fcm => _messaging ?? FirebaseMessaging.instance;

  /// Whether the devotee wants sign-up reminders: yes unless switched off.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(NotificationConstants.signupRemindersPrefKey) ?? true;
  }

  /// The devotee's switch: stores it, then subscribes to, or unsubscribes
  /// from, every slot this device is signed up for. Switching on also
  /// re-checks everything first, so ended slots aren't subscribed to.
  Future<void> setEnabled(bool enabled) => _serialized(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationConstants.signupRemindersPrefKey, enabled);
    final subscribed = <String>{};
    for (final slot in await _wanted()) {
      final topic = _topicOf(slot);
      if (enabled) {
        await _subscribe(topic);
        subscribed.add(topic);
      } else {
        await _unsubscribe(topic);
      }
    }
    if (enabled) await _syncEverything(alreadySubscribed: subscribed);
  });

  /// Brings this device's subscriptions for [signupId] in line with its
  /// entries: call it after the devotee takes a slot, claims their sign-up or
  /// cancels an entry, or opens their sign-ups. Throws, changing nothing, if
  /// the server can't be read.
  Future<void> syncSignup(String signupId) {
    if (kIsWeb) return Future<void>.value();
    return _serialized(() => _syncSignup(signupId));
  }

  /// Re-checks everything: finds every entry linked to this device (so sign-ups
  /// made before the reminders existed, or before a reinstall, are found too),
  /// subscribes to the upcoming slots among them, lets go of slots that are
  /// over, cancelled or taken off this device, renews the rest (topic
  /// subscriptions can be lost, e.g. with a new push token) and retries
  /// unsubscriptions that failed. Meant for app start-up; never throws.
  Future<void> syncAll() {
    if (kIsWeb) return Future<void>.value();
    return _serialized(() async {
      try {
        await _syncEverything();
      } on Exception catch (error) {
        debugPrint('SignupReminderSubscriptions: sync failed: $error');
      }
    });
  }

  /// Runs [action] after every operation queued before it, and keeps the
  /// queue going whether or not it fails.
  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// [alreadySubscribed] are topics that were just subscribed to, which a
  /// sweep need not subscribe to again.
  Future<void> _syncEverything({
    Set<String> alreadySubscribed = const {},
  }) async {
    await _retryStale();
    final wanted = await _wanted();
    final deviceId = await _deviceId();

    final List<({String signupId, SignupEntry entry})> mine;
    try {
      mine = await _signupService
          .fetchEntriesForDevice(deviceId)
          .timeout(_readTimeout);
    } on Exception catch (error) {
      // Can't look across sign-ups (offline, or an older server setup): check
      // the sign-ups we already know of one by one instead.
      debugPrint(
        'SignupReminderSubscriptions: could not list entries: '
        '$error',
      );
      for (final signupId in {for (final slot in wanted) slot.signupId}) {
        await _tryOn(signupId, () => _syncSignup(signupId));
      }
      return;
    }

    final entriesBySignup = <String, List<SignupEntry>>{};
    for (final found in mine) {
      (entriesBySignup[found.signupId] ??= []).add(found.entry);
    }
    final signupIds = {
      ...entriesBySignup.keys,
      for (final slot in wanted) slot.signupId,
    };
    for (final signupId in signupIds) {
      await _tryOn(signupId, () async {
        final entries = entriesBySignup[signupId] ?? const <SignupEntry>[];
        await _replace(
          signupId,
          await _upcomingSlotIds(signupId, entries),
          alreadySubscribed: alreadySubscribed,
        );
      });
    }
  }

  Future<void> _syncSignup(String signupId) async {
    final deviceId = await _deviceId();
    final entries = await _signupService
        .fetchEntriesByDevice(signupId, deviceId)
        .timeout(_readTimeout);
    await _replace(signupId, await _upcomingSlotIds(signupId, entries));
  }

  /// One sign-up's work during a sweep: a failure is logged and the other
  /// sign-ups still get their turn.
  Future<void> _tryOn(String signupId, Future<void> Function() work) async {
    try {
      await work();
    } on Exception catch (error) {
      debugPrint(
        'SignupReminderSubscriptions: could not sync $signupId: '
        '$error',
      );
    }
  }

  /// The ids of the slots [entries] are on that still have a reminder to
  /// give: scheduled and not over. Reads nothing for no entries.
  Future<Set<String>> _upcomingSlotIds(
    String signupId,
    List<SignupEntry> entries,
  ) async {
    if (entries.isEmpty) return const {};
    final signedUp = {for (final entry in entries) entry.slotId};
    final slots = await _signupService
        .fetchSlots(signupId)
        .timeout(_readTimeout);
    final now = _now();
    return {
      for (final SignupSlot slot in slots)
        if (slot.id != null &&
            signedUp.contains(slot.id) &&
            slot.hasSchedule &&
            !slot.isPast(now))
          slot.id!,
    };
  }

  /// Makes [signupId]'s wanted slots exactly [slotIds], subscribing to every
  /// one of them (again) if reminders are on and unsubscribing from those
  /// that left. A slot that leaves goes on the stale list before anything
  /// else, so being interrupted partway can't lose track of it.
  Future<void> _replace(
    String signupId,
    Set<String> slotIds, {
    Set<String> alreadySubscribed = const {},
  }) async {
    final all = await _wanted();
    final removed = [
      for (final slot in all)
        if (slot.signupId == signupId && !slotIds.contains(slot.slotId)) slot,
    ];
    await _rememberStale([for (final slot in removed) _topicOf(slot)]);
    await _saveWanted([
      for (final slot in all)
        if (slot.signupId != signupId) slot,
      for (final slotId in slotIds) _WantedSlot(signupId, slotId),
    ]);

    final enabled = await isEnabled();
    for (final slotId in slotIds) {
      final topic = _topicOf(_WantedSlot(signupId, slotId));
      await _forgetStale(topic);
      if (enabled) {
        if (!alreadySubscribed.contains(topic)) await _subscribe(topic);
      } else {
        await _unsubscribe(topic);
      }
    }
    for (final slot in removed) {
      final topic = _topicOf(slot);
      if (await _unsubscribe(topic)) await _forgetStale(topic);
    }
  }

  static String _topicOf(_WantedSlot slot) =>
      NotificationConstants.getSignupSlotReminderTopic(
        slot.signupId,
        slot.slotId,
      );

  /// Subscribes, giving up quietly on an error or a hang: the next
  /// [syncAll] tries again.
  Future<void> _subscribe(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic).timeout(_timeout);
    } on Exception catch (error) {
      debugPrint(
        'SignupReminderSubscriptions: subscribing to $topic failed: '
        '$error',
      );
    }
  }

  /// Unsubscribes; returns whether it worked.
  Future<bool> _unsubscribe(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic).timeout(_timeout);
      return true;
    } on Exception catch (error) {
      debugPrint(
        'SignupReminderSubscriptions: unsubscribing from $topic '
        'failed: $error',
      );
      return false;
    }
  }

  Future<void> _retryStale() async {
    for (final topic in await _stale()) {
      if (await _unsubscribe(topic)) await _forgetStale(topic);
    }
  }

  /// The wanted slots. Anything unreadable in the store is dropped (and
  /// logged) rather than breaking reminders until the app's data is cleared.
  Future<List<_WantedSlot>> _wanted() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_wantedKey);
    if (stored == null) return const [];
    try {
      return [
        for (final pair in (json.decode(stored) as List))
          _WantedSlot((pair as List)[0] as String, pair[1] as String),
      ];
    } on FormatException catch (error) {
      await _discardWanted(prefs, error);
    } on TypeError catch (error) {
      await _discardWanted(prefs, error);
    }
    return const [];
  }

  Future<void> _discardWanted(SharedPreferences prefs, Object error) async {
    debugPrint(
      'SignupReminderSubscriptions: dropping an unreadable list of '
      'slots: $error',
    );
    await prefs.remove(_wantedKey);
  }

  Future<void> _saveWanted(List<_WantedSlot> slots) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _wantedKey,
      json.encode([
        for (final slot in slots) [slot.signupId, slot.slotId],
      ]),
    );
  }

  Future<List<String>> _stale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_staleKey) ?? const [];
  }

  Future<void> _rememberStale(List<String> topics) async {
    if (topics.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _staleKey,
      {...await _stale(), ...topics}.toList(),
    );
  }

  Future<void> _forgetStale(String topic) async {
    final stale = await _stale();
    if (!stale.contains(topic)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_staleKey, [...stale]..remove(topic));
  }
}

class _WantedSlot {
  final String signupId;
  final String slotId;

  const _WantedSlot(this.signupId, this.slotId);
}

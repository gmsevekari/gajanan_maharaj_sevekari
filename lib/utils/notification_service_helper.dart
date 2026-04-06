import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';

class NotificationServiceHelper {
  static const String _pendingSubscriptionsKey = 'pending_fcm_subscriptions';

  /// Add a list of topics to be subscribed to in the background.
  static Future<void> addPendingSubscriptions(List<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_pendingSubscriptionsKey);
    List<String> pending = [];
    if (existingJson != null) {
      pending = List<String>.from(json.decode(existingJson));
    }

    // Add new topics if not already present
    for (var topic in topics) {
      if (!pending.contains(topic)) {
        pending.add(topic);
      }
    }

    await prefs.setString(_pendingSubscriptionsKey, json.encode(pending));

    // Trigger immediate attempt in background
    _processPendingSubscriptions();
  }

  /// Attempt to subscribe to all pending topics.
  static Future<void> _processPendingSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_pendingSubscriptionsKey);
    if (existingJson == null) return;

    List<String> pending = List<String>.from(json.decode(existingJson));
    if (pending.isEmpty) return;

    if (kIsWeb) {
      await prefs.remove(_pendingSubscriptionsKey);
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final List<String> succeeded = [];

    for (var topic in pending) {
      try {
        debugPrint('Attempting background subscription to topic: $topic');
        await messaging
            .subscribeToTopic(topic)
            .timeout(const Duration(seconds: 10));
        succeeded.add(topic);
        debugPrint('Successfully subscribed to topic: $topic');
      } catch (e) {
        debugPrint('Failed to subscribe to topic $topic: $e');
        // Will retry on next app start or next enrollment
      }
    }

    if (succeeded.isNotEmpty) {
      pending.removeWhere((topic) => succeeded.contains(topic));
      if (pending.isEmpty) {
        await prefs.remove(_pendingSubscriptionsKey);
      } else {
        await prefs.setString(_pendingSubscriptionsKey, json.encode(pending));
      }
    }
  }

  /// Process any pending subscriptions - call this on app startup.
  static Future<void> processOnStartup() async {
    // Small delay to ensure firebase is ready and network might be stable
    Future.delayed(const Duration(seconds: 5), () {
      _processPendingSubscriptions();
      syncActiveParayanSubscriptions();
      cleanUpOldSubscriptions();
    });
  }

  /// Syncs subscriptions for all active (upcoming/ongoing) parayan enrollments.
  /// Call this on app startup to ensure existing users stay subscribed to topics.
  static Future<void> syncActiveParayanSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersEnabled =
          prefs.getBool(NotificationConstants.parayanRemindersPrefKey) ?? true;
      if (!remindersEnabled || kIsWeb) return;

      final deviceId = await UniqueIdService.getUniqueId();
      final parayanService = ParayanService();

      // Get all active enrollments for this device
      final enrollments = await parayanService
          .getMyActiveEnrollmentsWithHousehold(deviceId);

      final messaging = FirebaseMessaging.instance;
      for (var entry in enrollments) {
        final event = entry['event'];
        final household = entry['household'];
        if (event is! ParayanEvent || household is! ParayanHousehold) continue;

        // Subscribe to all days needed for the event type, but check completion first
        final int daysInEvent = (event.type == ParayanType.threeDay) ? 3 : 1;
        for (int day = 1; day <= daysInEvent; day++) {
          final topic = NotificationConstants.getParayanReminderTopic(
            event.id,
            day,
          );

          // Check if EVERY member in this household has completed THIS specific day
          final allDoneForDay = household.members.values.every(
            (m) => m.completions[day.toString()] == true,
          );

          if (allDoneForDay) {
            debugPrint(
              'Sync: Unsubscribing from $topic - All members completed.',
            );
            await messaging
                .unsubscribeFromTopic(topic)
                .timeout(const Duration(seconds: 5));
          } else {
            debugPrint('Sync: Subscribing to $topic - Pending adhyays found.');
            await messaging
                .subscribeToTopic(topic)
                .timeout(const Duration(seconds: 5));
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing active parayan subscriptions: $e');
    }
  }

  /// Scan all user enrollments and unsubscribe from completed ones.
  static Future<void> cleanUpOldSubscriptions() async {
    try {
      final deviceId = await UniqueIdService.getUniqueId();

      final parayanService = ParayanService();
      final enrollments = await parayanService.getAllMyEnrollments(deviceId);

      for (var entry in enrollments) {
        final event = entry['event'];
        if (event.status == 'completed') {
          await unsubscribeFromEventTopics(event.id);
        }
      }
    } catch (e) {
      debugPrint('Error in global subscription cleanup: $e');
    }
  }

  /// Unsubscribe from reminder topics for a specific event.
  static Future<void> unsubscribeFromEventTopics(String eventId) async {
    if (kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      debugPrint('Unsubscribing from topics for completed event: $eventId');
      await Future.wait([
        messaging
            .unsubscribeFromTopic('parayan_${eventId}_day1')
            .timeout(const Duration(seconds: 5)),
        messaging
            .unsubscribeFromTopic('parayan_${eventId}_day2')
            .timeout(const Duration(seconds: 5)),
        messaging
            .unsubscribeFromTopic('parayan_${eventId}_day3')
            .timeout(const Duration(seconds: 5)),
      ]);
    } catch (e) {
      debugPrint('Error unsubscribing from event $eventId: $e');
    }
  }
}

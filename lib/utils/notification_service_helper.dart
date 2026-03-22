import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';

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

    final messaging = FirebaseMessaging.instance;
    final List<String> succeeded = [];

    for (var topic in pending) {
      try {
        debugPrint('Attempting background subscription to topic: $topic');
        await messaging.subscribeToTopic(topic).timeout(const Duration(seconds: 10));
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
      cleanUpOldSubscriptions();
    });
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
    try {
      final messaging = FirebaseMessaging.instance;
      debugPrint('Unsubscribing from topics for completed event: $eventId');
      await Future.wait([
        messaging.unsubscribeFromTopic('parayan_reminders_${eventId}_1').timeout(const Duration(seconds: 5)),
        messaging.unsubscribeFromTopic('parayan_reminders_${eventId}_2').timeout(const Duration(seconds: 5)),
        messaging.unsubscribeFromTopic('parayan_reminders_${eventId}_3').timeout(const Duration(seconds: 5)),
      ]);
    } catch (e) {
      debugPrint('Error unsubscribing from event $eventId: $e');
    }
  }
}

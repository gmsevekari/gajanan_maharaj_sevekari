import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  static const String _firstRunKey = 'first_run';

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool(_firstRunKey) ?? true;

    if (isFirstRun) {
      await _firstTimeSetup(prefs);
    }
  }

  static Future<void> _firstTimeSetup(SharedPreferences prefs) async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (!kIsWeb) {
        await messaging.subscribeToTopic(NotificationConstants.weeklyPoojaTopic);
      }
      await prefs.setBool(NotificationConstants.weeklyPoojaReminderPrefKey, true);
    }

    await prefs.setBool(_firstRunKey, false);
  }
}

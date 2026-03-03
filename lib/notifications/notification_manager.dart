import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  static const String _firstRunKey = 'first_run';

  static Future<void> initialize() async {
    // Optional background message handlers can be set up here in the future
  }

  static Future<void> requestPermissions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool(_firstRunKey) ?? true;

    if (isFirstRun) {
      if (!context.mounted) return;
      await _showCustomNotificationDialog(context, prefs);
    }
  }

  static Future<void> _showCustomNotificationDialog(BuildContext context, SharedPreferences prefs) async {
    final localizations = AppLocalizations.of(context)!;

    final bool? shouldAllow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(
            Icons.notifications_active_outlined,
            size: 48,
            color: Colors.orange[600] ?? theme.colorScheme.primary,
          ),
          title: Text(
            localizations.notificationDialogTitle,
            style: TextStyle(
              color: Colors.orange[600] ?? theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            localizations.notificationDialogBody,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: Text(localizations.notificationDialogDeny),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600] ?? theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: Text(
                localizations.notificationDialogAllow,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldAllow == true) {
      await _firstTimeSetup(prefs);
    } else {
       await prefs.setBool(_firstRunKey, false);
    }
  }

  static Future<void> _firstTimeSetup(SharedPreferences prefs) async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (!kIsWeb) {
          try {
            await messaging.subscribeToTopic(NotificationConstants.weeklyPoojaTopic);
          } catch (e) {
            debugPrint('Failed to subscribe to topic: $e');
          }
        }
        await prefs.setBool(NotificationConstants.weeklyPoojaReminderPrefKey, true);
      }
    } finally {
      await prefs.setBool(_firstRunKey, false);
    }
  }
}

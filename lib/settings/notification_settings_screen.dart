import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> with WidgetsBindingObserver {
  bool _weeklyPoojaReminder = true;
  NotificationStatus _notificationStatus = NotificationStatus.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _checkNotificationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationStatus();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weeklyPoojaReminder = prefs.getBool(NotificationConstants.weeklyPoojaReminderPrefKey) ?? true;
    });
  }

  Future<void> _checkNotificationStatus() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.getNotificationSettings();
    setState(() {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _notificationStatus = NotificationStatus.authorized;
      } else {
        _notificationStatus = NotificationStatus.denied;
      }
    });
  }

  Future<void> _updateSubscription(String topic, bool subscribed) async {
    final messaging = FirebaseMessaging.instance;
    final prefs = await SharedPreferences.getInstance();

    if (subscribed) {
      if (!kIsWeb) {
        try {
          await messaging.subscribeToTopic(topic);
        } catch (e) {
          debugPrint('Failed to subscribe to topic ($topic): $e');
        }
      }
      await prefs.setBool(NotificationConstants.weeklyPoojaReminderPrefKey, true);
    } else {
      if (!kIsWeb) {
        try {
          await messaging.unsubscribeFromTopic(topic);
        } catch (e) {
          debugPrint('Failed to unsubscribe from topic ($topic): $e');
        }
      }
      await prefs.setBool(NotificationConstants.weeklyPoojaReminderPrefKey, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final canChangeSubscriptions = _notificationStatus == NotificationStatus.authorized;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.notificationPreferences),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          Card(
            elevation: theme.cardTheme.elevation,
            color: theme.cardTheme.color,
            shape: theme.cardTheme.shape,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SwitchListTile(
              title: Text(
                localizations.weeklyPoojaReminder,
                style: TextStyle(
                  color: canChangeSubscriptions ? Colors.orange[600] : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              value: canChangeSubscriptions && _weeklyPoojaReminder,
              onChanged: canChangeSubscriptions
                  ? (bool value) {
                      setState(() {
                        _weeklyPoojaReminder = value;
                      });
                      _updateSubscription(NotificationConstants.weeklyPoojaTopic, value);
                    }
                  : null,
            ),
          ),
          if (!canChangeSubscriptions)
            Card(
              elevation: 0,
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3), width: 1),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: theme.colorScheme.primary),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            localizations.notificationsDisabledMessage,
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (!kIsWeb) ...[
                      const SizedBox(height: 12.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          AppSettings.openAppSettings(type: AppSettingsType.notification);
                        },
                        icon: const Icon(Icons.settings),
                        label: Text(localizations.openSettings),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum NotificationStatus {
  unknown,
  authorized,
  denied,
}

import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:gajanan_maharaj_sevekari/notifications/signup_reminder_subscriptions.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

class NotificationSettingsScreen extends StatefulWidget {
  /// Injected for testing; defaults to this device's real subscriptions.
  @visibleForTesting
  final SignupReminderSubscriptions? signupReminders;

  /// Injected for testing; defaults to asking Firebase Messaging whether the
  /// app may show notifications.
  @visibleForTesting
  final Future<bool> Function()? isAuthorized;

  const NotificationSettingsScreen({
    super.key,
    this.signupReminders,
    this.isAuthorized,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _templeNotifications = true;
  bool _parayanReminders = true;
  bool _signupReminders = true;
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
    if (!mounted) return;
    setState(() {
      _templeNotifications =
          prefs.getBool(NotificationConstants.templeNotificationsPrefKey) ??
          true;
      _parayanReminders =
          prefs.getBool(NotificationConstants.parayanRemindersPrefKey) ?? true;
      _signupReminders =
          prefs.getBool(NotificationConstants.signupRemindersPrefKey) ?? true;
    });
  }

  Future<bool> _isAuthorized() async {
    final custom = widget.isAuthorized;
    if (custom != null) return custom();
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<void> _checkNotificationStatus() async {
    final authorized = await _isAuthorized();
    if (!mounted) return;
    setState(() {
      if (authorized) {
        _notificationStatus = NotificationStatus.authorized;
      } else {
        _notificationStatus = NotificationStatus.denied;
      }
    });
  }

  Future<void> _updateSubscription(String topic, bool subscribed) async {
    final messaging = FirebaseMessaging.instance;
    final prefs = await SharedPreferences.getInstance();

    bool isIosSimulator = false;
    if (!kIsWeb && Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      isIosSimulator = !iosInfo.isPhysicalDevice;
    }

    if (subscribed) {
      if (!kIsWeb && !isIosSimulator) {
        try {
          await messaging.subscribeToTopic(topic);
        } catch (e) {
          debugPrint('Failed to subscribe to topic ($topic): $e');
        }
      }
      await prefs.setBool(
        NotificationConstants.templeNotificationsPrefKey,
        true,
      );
    } else {
      if (!kIsWeb && !isIosSimulator) {
        try {
          await messaging.unsubscribeFromTopic(topic);
        } catch (e) {
          debugPrint('Failed to unsubscribe from topic ($topic): $e');
        }
      }
      await prefs.setBool(
        NotificationConstants.templeNotificationsPrefKey,
        false,
      );
    }
  }

  /// Turns this device's sign-up slot reminders on or off. The choice is kept
  /// even if the subscriptions can't be changed right now: the next start-up
  /// sync brings them in line.
  Future<void> _updateSignupReminders(bool enabled) async {
    // Kept at once, like the other switches: the subscription changes below
    // can queue behind a start-up sync, and the choice mustn't wait for them.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationConstants.signupRemindersPrefKey, enabled);
    final reminders =
        widget.signupReminders ?? SignupReminderSubscriptions.forThisDevice();
    try {
      await reminders.setEnabled(enabled);
    } on Exception catch (e) {
      debugPrint('Failed to update sign-up reminder subscriptions: $e');
    }
  }

  Future<void> _updateParayanSubscription(bool subscribed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      NotificationConstants.parayanRemindersPrefKey,
      subscribed,
    );

    bool isIosSimulator = false;
    if (!kIsWeb && Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      isIosSimulator = !iosInfo.isPhysicalDevice;
    }
    if (kIsWeb || isIosSimulator) return;

    final deviceId = await UniqueIdService.getUniqueId();

    try {
      final messaging = FirebaseMessaging.instance;
      final enrollments = await ParayanService()
          .getMyActiveEnrollmentsWithHousehold(deviceId);

      for (var enrollment in enrollments) {
        final event = enrollment['event'] as ParayanEvent;
        final household = enrollment['household'] as ParayanHousehold;

        if (event.type == ParayanType.oneDay ||
            event.type == ParayanType.guruPushya) {
          bool allCompleted = household.members.values.every(
            (m) => m.completions['1'] == true,
          );
          if (!allCompleted) {
            final topic = NotificationConstants.getParayanReminderTopic(
              event.id,
              1,
            );
            if (subscribed) {
              await messaging.subscribeToTopic(topic);
            } else {
              await messaging.unsubscribeFromTopic(topic);
            }
          }
        } else {
          for (int i = 1; i <= 3; i++) {
            bool allCompleted = household.members.values.every(
              (m) => m.completions[i.toString()] == true,
            );
            if (!allCompleted) {
              final topic = NotificationConstants.getParayanReminderTopic(
                event.id,
                i,
              );
              if (subscribed) {
                await messaging.subscribeToTopic(topic);
              } else {
                await messaging.unsubscribeFromTopic(topic);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to update parayan subscriptions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final canChangeSubscriptions =
        _notificationStatus == NotificationStatus.authorized;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.notificationPreferences),
        actions: [
          IconButton(
            icon: const ThemedIcon(LogicalIcon.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
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
                localizations.templeNotifications,
                style: TextStyle(
                  color: canChangeSubscriptions
                      ? theme.appColors.primarySwatch[600]
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                localizations.templeNotificationsNote,
                style: TextStyle(
                  color: canChangeSubscriptions
                      ? Colors.grey[600]
                      : Colors.grey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              value: canChangeSubscriptions && _templeNotifications,
              onChanged: canChangeSubscriptions
                  ? (bool value) {
                      setState(() {
                        _templeNotifications = value;
                      });
                      _updateSubscription(
                        NotificationConstants.templeNotificationsTopic,
                        value,
                      );
                    }
                  : null,
            ),
          ),
          Card(
            elevation: theme.cardTheme.elevation,
            color: theme.cardTheme.color,
            shape: theme.cardTheme.shape,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SwitchListTile(
              title: Text(
                localizations.parayanReminders,
                style: TextStyle(
                  color: canChangeSubscriptions
                      ? theme.appColors.primarySwatch[600]
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                localizations.parayanRemindersNote,
                style: TextStyle(
                  color: canChangeSubscriptions
                      ? Colors.grey[600]
                      : Colors.grey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              value: canChangeSubscriptions && _parayanReminders,
              onChanged: canChangeSubscriptions
                  ? (bool value) {
                      setState(() {
                        _parayanReminders = value;
                      });
                      _updateParayanSubscription(value);
                    }
                  : null,
            ),
          ),
          Card(
            elevation: theme.cardTheme.elevation,
            color: theme.cardTheme.color,
            shape: theme.cardTheme.shape,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SwitchListTile(
              title: Text(
                localizations.signupReminders,
                style: TextStyle(
                  color: canChangeSubscriptions
                      ? theme.appColors.primarySwatch[600]
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                localizations.signupRemindersNote,
                style: TextStyle(
                  color: canChangeSubscriptions
                      ? Colors.grey[600]
                      : Colors.grey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              value: canChangeSubscriptions && _signupReminders,
              onChanged: canChangeSubscriptions
                  ? (bool value) {
                      setState(() {
                        _signupReminders = value;
                      });
                      unawaited(_updateSignupReminders(value));
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
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              margin: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
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
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!kIsWeb) ...[
                      const SizedBox(height: 12.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          AppSettings.openAppSettings(
                            type: AppSettingsType.notification,
                          );
                        },
                        icon: const ThemedIcon(LogicalIcon.settings),
                        label: Text(localizations.openSettings),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              theme.appBarTheme.backgroundColor ??
                              theme.primaryColor,
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

enum NotificationStatus { unknown, authorized, denied }

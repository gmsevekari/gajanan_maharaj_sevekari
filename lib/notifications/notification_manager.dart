import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('--- FCM BACKGROUND MESSAGE RECEIVED ---');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('Data: ${message.data}');

  // We need to initialize the local notifications plugin in the background isolate
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_notification');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await NotificationManager.localNotifications.initialize(
    settings: initializationSettings,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  await NotificationManager.showLocalNotification(message);
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background action taps
  if (notificationResponse.actionId == 'action_mark_read') {
    final String? notificationId = notificationResponse.payload;
    final now = DateTime.now().toIso8601String();

    SharedPreferences.getInstance().then((prefs) {
      // 1. Mark individual notification as read
      if (notificationId != null) {
        final List<String> readIds =
            prefs.getStringList('read_notifications') ?? [];
        if (!readIds.contains(notificationId)) {
          readIds.add(notificationId);
          prefs.setStringList('read_notifications', readIds);
        }
      }
      // 2. Sync global last read timestamp to clear red dot on Home Screen
      prefs.setString('last_read_notification_timestamp', now);
    });
  } else if (notificationResponse.actionId == 'action_open_link') {
    // Note: On Android, this might still fail if called in background isolate.
    // For reliable URL opening, we should use foreground actions.
    final String? url = notificationResponse.payload;
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

class NotificationManager {
  static const String _firstRunKey = 'first_run';
  static final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    debugPrint('NotificationManager: Initializing...');
    // 1. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              'with_link',
              actions: [
                DarwinNotificationAction.plain(
                  'action_open_link',
                  'Open Link',
                  options: {DarwinNotificationActionOption.foreground},
                ),
                DarwinNotificationAction.plain(
                  'action_mark_read',
                  'Mark as Read',
                  options: {DarwinNotificationActionOption.destructive},
                ),
              ],
            ),
            DarwinNotificationCategory(
              'plain',
              actions: [
                DarwinNotificationAction.plain(
                  'action_mark_read',
                  'Mark as Read',
                  options: {DarwinNotificationActionOption.destructive},
                ),
              ],
            ),
          ],
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationResponse(response, navigatorKey);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 2. Handle Foreground FCM Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('--- FCM FOREGROUND MESSAGE RECEIVED ---');
      debugPrint('Message ID: ${message.messageId}');
      debugPrint('Data: ${message.data}');
      showLocalNotification(message);
    });

    // 3. Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigatorKey.currentState?.pushNamed(Routes.userNotifications);
    });

    // 4. Handle notification tap when app was terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamed(Routes.userNotifications);
      });
    }

    // 5. Ensure topic subscription if already authorized
    _ensureSubscription();
  }

  static Future<void> cancelAllNotifications() async {
    debugPrint('NotificationManager: Cancelling all notifications');
    await localNotifications.cancelAll();
  }

  static Future<void> _ensureSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthorized =
        prefs.getBool(NotificationConstants.templeNotificationsPrefKey) ??
        false;
    debugPrint(
      'NotificationManager: isAuthorized for notifications: $isAuthorized',
    );
    if (isAuthorized && !kIsWeb) {
      debugPrint(
        'NotificationManager: Subscribing to topic: ${NotificationConstants.templeNotificationsTopic}',
      );
      await FirebaseMessaging.instance.subscribeToTopic(
        NotificationConstants.templeNotificationsTopic,
      );
    }
  }

  static void _handleNotificationResponse(
    NotificationResponse response,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (response.actionId == 'action_mark_read') {
      final String? notificationId = response.payload;
      if (notificationId != null) {
        final prefs = await SharedPreferences.getInstance();
        final List<String> readIds =
            prefs.getStringList('read_notifications') ?? [];
        if (!readIds.contains(notificationId)) {
          readIds.add(notificationId);
          await prefs.setStringList('read_notifications', readIds);
        }
      }
    } else if (response.actionId == 'action_open_link') {
      final String? url = response.payload;
      if (url != null) {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } else {
      // Default tap: Open notifications screen
      navigatorKey.currentState?.pushNamed(Routes.userNotifications);
    }
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    debugPrint('NotificationManager: showLocalNotification called');
    final notification = message.notification;
    final data = message.data;

    String? title = notification?.title ?? data['title'];
    String? body = notification?.body ?? data['body'];

    debugPrint('Title: $title, Body: $body');

    // If both are null, we can't show a notification
    if (title == null && body == null) {
      debugPrint('NotificationManager: Error - Title and Body are both null');
      return;
    }

    // Prioritize explicit link/url fields from data, then fall back to body regex
    String? link = data['link'] ?? data['url'];
    if (link == null || link.isEmpty) {
      final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);
      final match = urlRegex.firstMatch(body ?? '');
      link = match?.group(0);
    }

    // Clean empty link strings
    if (link != null && link.isEmpty) link = null;

    final List<AndroidNotificationAction> androidActions = [];
    final List<DarwinNotificationAction> darwinActions = [];

    // Add Mark as Read action
    androidActions.add(
      AndroidNotificationAction(
        'action_mark_read',
        'Mark as Read',
        cancelNotification: true,
      ),
    );
    darwinActions.add(
      DarwinNotificationAction.plain(
        'action_mark_read',
        'Mark as Read',
        options: {DarwinNotificationActionOption.destructive},
      ),
    );

    // Add Open Link action if link exists
    if (link != null) {
      androidActions.add(
        AndroidNotificationAction(
          'action_open_link',
          'Open Link',
          showsUserInterface:
              true, // This helps bring app to foreground or handle intent properly
        ),
      );
      darwinActions.add(
        DarwinNotificationAction.plain(
          'action_open_link',
          'Open Link',
          options: {DarwinNotificationActionOption.foreground},
        ),
      );
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'temple_notifications_v3',
          'Temple Notifications',
          channelDescription: 'Broadcast notifications for temple events',
          importance: Importance.max,
          priority: Priority.high,
          actions: androidActions,
        );

    final DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: link != null ? 'with_link' : 'plain',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: link ?? message.messageId ?? data['id'],
    );
  }

  static Future<void> requestPermissions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool(_firstRunKey) ?? true;

    if (isFirstRun) {
      if (!context.mounted) return;
      await _showCustomNotificationDialog(context, prefs);
    }
  }

  static Future<void> _showCustomNotificationDialog(
    BuildContext context,
    SharedPreferences prefs,
  ) async {
    final localizations = AppLocalizations.of(context)!;

    final bool? shouldAllow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Icon(
            Icons.notifications_active_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            localizations.notificationDialogTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
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
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              child: Text(localizations.notificationDialogDeny),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: const StadiumBorder(),
              ),
              child: Text(
                localizations.notificationDialogAllow,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
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
          bool isIosSimulator = false;
          if (Platform.isIOS) {
            final deviceInfo = DeviceInfoPlugin();
            final iosInfo = await deviceInfo.iosInfo;
            isIosSimulator = !iosInfo.isPhysicalDevice;
          }

          if (!isIosSimulator) {
            try {
              await messaging.subscribeToTopic(
                NotificationConstants.templeNotificationsTopic,
              );
              await messaging.unsubscribeFromTopic('weekly_pooja');
            } catch (e) {
              debugPrint('Failed to subscribe to topic: $e');
            }
          } else {
            debugPrint('Bypassing APNS topic subscription on iOS Simulator.');
          }
        }
        await prefs.setBool(
          NotificationConstants.templeNotificationsPrefKey,
          true,
        );
      }
    } finally {
      await prefs.setBool(_firstRunKey, false);
    }
  }
}

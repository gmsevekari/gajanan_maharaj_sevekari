import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_channels.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_routing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/providers/typo_report_service.dart';

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

  await NotificationManager.showLocalNotification(message, isForeground: false);
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background notification taps if needed.
  // Custom actions have been removed for simplicity.
}

class NotificationManager {
  static const String _firstRunKey = 'first_run';
  static final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Used to store a route that should be navigated to once the app is ready.
  /// This prevents the Splash Screen from overwriting the notification navigation.
  static String? pendingRoute;

  /// The arguments for [pendingRoute], if it needs any.
  static Object? pendingRouteArguments;

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
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        handleNotificationResponse(response, navigatorKey);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 2. Set iOS Foreground Presentation Options (Important for "bubbles")
    if (!kIsWeb && Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      debugPrint(
        'NotificationManager: iOS foreground presentation options set.',
      );
    }

    // 3. Handle Foreground FCM Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('--- FCM FOREGROUND MESSAGE RECEIVED ---');
      debugPrint('Message ID: ${message.messageId}');
      debugPrint('Data: ${message.data}');
      showLocalNotification(message, isForeground: true);
    });

    // 3. Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      openFromMessage(message, navigatorKey);
    });

    // 4. Handle notification tap when app was terminated
    // A. Check for FCM terminated-state click
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '[FCM] App launched from terminated state via FCM notification.',
      );
      setPendingTarget(NotificationRouting.forMessageData(initialMessage.data));
    }

    // B. Check for Local Notification terminated-state click (Common on Android)
    final localLaunchDetails = await localNotifications
        .getNotificationAppLaunchDetails();
    if (localLaunchDetails?.didNotificationLaunchApp == true) {
      debugPrint(
        '[FCM] App launched from terminated state via local notification.',
      );
      setPendingTarget(
        NotificationRouting.forPayload(
          localLaunchDetails?.notificationResponse?.payload,
        ),
      );
    }

    // 5. Ensure topic subscription if already authorized
    _ensureSubscription();

    // 6. Register the sign-up reminders channel. Last, and not waited for, so
    // nothing above depends on it and a slow call can't hold up the app.
    unawaited(_createChannels());
  }

  /// Android needs the sign-up reminders channel to exist before a reminder
  /// arrives while the app is closed (the system shows it under that channel).
  static Future<void> _createChannels() async {
    if (kIsWeb) return;
    try {
      await NotificationChannels.createSignupReminders(localNotifications);
    } on Exception catch (e) {
      debugPrint('NotificationManager: could not create channel: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    debugPrint('NotificationManager: Cancelling all notifications');
    await localNotifications.cancelAll();

    // Clear the badge using flutter_app_badge_control
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS || Platform.isAndroid)) {
      FlutterAppBadgeControl.removeBadge();
      debugPrint('NotificationManager: Badge cleared.');
    }
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
      // 1. Temple Notifications (US Only)
      if (isUSRegion()) {
        debugPrint(
          'NotificationManager: US Region detected. Subscribing to topic: ${NotificationConstants.templeNotificationsTopic}',
        );
        await FirebaseMessaging.instance.subscribeToTopic(
          NotificationConstants.templeNotificationsTopic,
        );
      } else {
        debugPrint(
          'NotificationManager: Non-US Region (${WidgetsBinding.instance.platformDispatcher.locale.countryCode}). Skipping Temple Notifications topic.',
        );
        await FirebaseMessaging.instance.unsubscribeFromTopic(
          NotificationConstants.templeNotificationsTopic,
        );
      }
    }

    // 2. Typo Report Notifications (Admin)
    if (!kIsWeb) {
      try {
        final typoEnabled = await TypoReportService.areNotificationsEnabled();
        if (typoEnabled) {
          debugPrint(
            'NotificationManager: Typo Notifications Enabled. Subscribing to: ${TypoReportService.typoTopic}',
          );
          await FirebaseMessaging.instance.subscribeToTopic(
            TypoReportService.typoTopic,
          );
        }
      } catch (e) {
        debugPrint('Error syncing typo report topic: $e');
      }
    }
  }

  /// A tap on a notification the app showed itself: a sign-up reminder opens
  /// its sign-up; anything else, the notifications screen.
  @visibleForTesting
  static void handleNotificationResponse(
    NotificationResponse response,
    GlobalKey<NavigatorState> navigatorKey,
  ) => _open(NotificationRouting.forPayload(response.payload), navigatorKey);

  /// A tap, with the app in the background, on a notification the system
  /// showed.
  @visibleForTesting
  static void openFromMessage(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) => _open(NotificationRouting.forMessageData(message.data), navigatorKey);

  static void _open(
    NotificationTarget target,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    navigatorKey.currentState?.pushNamed(
      target.route,
      arguments: target.arguments,
    );
  }

  /// Remembers where to go once the app has started (see the splash screen):
  /// the route and its arguments always together, so an earlier target's
  /// arguments can't leak into a later one.
  @visibleForTesting
  static void setPendingTarget(NotificationTarget target) {
    pendingRoute = target.route;
    pendingRouteArguments = target.arguments;
  }

  /// Consumes and returns the pending route if any.
  /// This should be called by the Splash Screen after its transition logic.
  static String? consumePendingRoute() {
    final route = pendingRoute;
    pendingRoute = null;
    if (route != null) {
      debugPrint('[FCM] Pending route consumed: $route');
    }
    return route;
  }

  /// Consumes and returns the arguments that go with the pending route.
  static Object? consumePendingRouteArguments() {
    final arguments = pendingRouteArguments;
    pendingRouteArguments = null;
    return arguments;
  }

  static Future<void> showLocalNotification(
    RemoteMessage message, {
    bool isForeground = false,
  }) async {
    debugPrint(
      'NotificationManager: showLocalNotification called (isForeground: $isForeground)',
    );
    final notification = message.notification;
    final data = message.data;

    // IMPORTANT: Avoid double notifications.
    if (notification != null) {
      if (Platform.isIOS) {
        // iOS always handles notification blocks via APNS or presentation options.
        // If we show a local one too, user gets two bubbles.
        debugPrint(
          '[FCM] iOS Notification block present — system handles display. Skipping.',
        );
        return;
      }
      if (Platform.isAndroid && !isForeground) {
        // Android background handles notification blocks via system.
        // In foreground, Android does NOT show a banner for notification blocks, so we proceed.
        debugPrint(
          '[FCM] Android Background Notification — system already showed it. Skipping.',
        );
        return;
      }
    }

    String? title = notification?.title ?? data['title'];
    String? body = notification?.body ?? data['body'];

    debugPrint('Title: $title, Body: $body');

    // If both are null, we can't show a notification
    if (title == null && body == null) {
      debugPrint('NotificationManager: Error - Title and Body are both null');
      return;
    }

    final androidDetails = NotificationChannels.detailsFor(data);

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payloadFor(message),
    );
  }

  /// What a tap on the locally shown notification gets told: the sign-up for
  /// a sign-up reminder, otherwise the notification's id.
  @visibleForTesting
  static String? payloadFor(RemoteMessage message) {
    final data = message.data;
    final signupId = data['signup_id'];
    if (data['type'] == NotificationRouting.signupReminderType &&
        signupId is String &&
        signupId.isNotEmpty) {
      return NotificationRouting.payloadForSignup(signupId);
    }
    return data['notification_id'] ?? message.messageId ?? data['id'];
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
    final theme = Theme.of(context);

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
          titlePadding: const EdgeInsets.only(top: 16),
          content: Text(
            localizations.notificationDialogBody,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.appColors.secondaryText,
              ),
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
              // 1. Temple Notifications (US Only)
              if (isUSRegion()) {
                debugPrint(
                  'NotificationManager: US Region detected during setup. Subscribing to ${NotificationConstants.templeNotificationsTopic}',
                );
                await messaging.subscribeToTopic(
                  NotificationConstants.templeNotificationsTopic,
                );
              } else {
                debugPrint(
                  'NotificationManager: Non-US region detected during setup. Skipping ${NotificationConstants.templeNotificationsTopic}',
                );
              }

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

  /// Helper to check if the device region is set to US.
  static bool isUSRegion() {
    try {
      final countryCode =
          WidgetsBinding.instance.platformDispatcher.locale.countryCode;
      debugPrint('NotificationManager: Detected Country Code: $countryCode');
      return countryCode?.toUpperCase() == 'US';
    } catch (e) {
      debugPrint('NotificationManager: Error detecting region: $e');
      return false; // Default to false if we can't detect
    }
  }
}

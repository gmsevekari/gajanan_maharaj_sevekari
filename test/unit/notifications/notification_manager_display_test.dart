import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_manager.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;
  Object? failWith;

  setUp(() {
    calls = [];
    failWith = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (failWith != null) throw failWith!;
          return null;
        });
    NotificationManager.pendingRoute = null;
    NotificationManager.pendingRouteArguments = null;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    NotificationManager.pendingRoute = null;
    NotificationManager.pendingRouteArguments = null;
  });

  Map<Object?, Object?> shown() {
    final show = calls.singleWhere((c) => c.method == 'show');
    return show.arguments as Map<Object?, Object?>;
  }

  Map<Object?, Object?> platformSpecifics(Map<Object?, Object?> shown) =>
      shown['platformSpecifics'] as Map<Object?, Object?>;

  group('showing a push the app displays itself', () {
    test(
      'a sign-up reminder uses its own channel and opens its sign-up',
      () async {
        await NotificationManager.showLocalNotification(
          RemoteMessage(
            messageId: 'm1',
            data: {
              'type': 'SIGNUP_REMINDER',
              'signup_id': 'sign1',
              'slot_id': 'slotA',
              'title': 'Reminder: Prasad Seva is tomorrow',
              'body': 'Seattle GM Parivar - Prasad Seva',
            },
          ),
          isForeground: true,
        );

        final arguments = shown();
        expect(arguments['payload'], 'signup:sign1');
        expect(platformSpecifics(arguments)['channelId'], 'signup_reminders');
        expect(arguments['title'], 'Reminder: Prasad Seva is tomorrow');
      },
    );

    test(
      'any other push keeps the temple channel and its usual payload',
      () async {
        await NotificationManager.showLocalNotification(
          RemoteMessage(
            messageId: 'm1',
            data: {
              'type': 'TEMPLE_NOTIFICATION',
              'notification_id': 'n1',
              'title': 'Palkhi',
              'body': 'Today',
            },
          ),
          isForeground: true,
        );

        final arguments = shown();
        expect(arguments['payload'], 'n1');
        expect(
          platformSpecifics(arguments)['channelId'],
          'temple_notifications',
        );
      },
    );

    test('a push with no text is not shown', () async {
      await NotificationManager.showLocalNotification(
        RemoteMessage(data: {'type': 'SIGNUP_REMINDER', 'signup_id': 's'}),
        isForeground: true,
      );

      expect(calls.where((c) => c.method == 'show'), isEmpty);
    });
  });

  group('the sign-up reminders channel at start-up', () {
    test('is registered with Android', () async {
      await NotificationManager.createChannels();

      final created = calls.where(
        (c) => c.method == 'createNotificationChannel',
      );
      expect(created, hasLength(1));
      expect(
        (created.single.arguments as Map<Object?, Object?>)['id'],
        'signup_reminders',
      );
    });

    test('a failure to register it is survived', () async {
      failWith = PlatformException(code: 'boom');

      await NotificationManager.createChannels(); // does not throw

      expect(
        calls.where((c) => c.method == 'createNotificationChannel'),
        hasLength(1),
      );
    });
  });

  group('the notification that launched the app', () {
    NotificationAppLaunchDetails launchedBy(String? payload) =>
        NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: payload,
          ),
        );

    test('a pushed sign-up reminder opens its sign-up after start-up', () {
      NotificationManager.adoptLaunchNotification(
        initialMessage: RemoteMessage(
          data: {'type': 'SIGNUP_REMINDER', 'signup_id': 's1'},
        ),
      );

      expect(NotificationManager.pendingRoute, Routes.signupDetail);
      expect(NotificationManager.pendingRouteArguments, {'signupId': 's1'});
    });

    test('any other pushed notification opens the inbox', () {
      NotificationManager.adoptLaunchNotification(
        initialMessage: RemoteMessage(data: {'type': 'TEMPLE_NOTIFICATION'}),
      );

      expect(NotificationManager.pendingRoute, Routes.userNotifications);
      expect(NotificationManager.pendingRouteArguments, isNull);
    });

    test('a shown sign-up reminder opens its sign-up after start-up', () {
      NotificationManager.adoptLaunchNotification(
        launchDetails: launchedBy('signup:s1'),
      );

      expect(NotificationManager.pendingRoute, Routes.signupDetail);
      expect(NotificationManager.pendingRouteArguments, {'signupId': 's1'});
    });

    test('a shown notification with another payload opens the inbox', () {
      NotificationManager.adoptLaunchNotification(
        launchDetails: launchedBy('n1'),
      );

      expect(NotificationManager.pendingRoute, Routes.userNotifications);
    });

    test('an app not launched by a notification has nothing pending', () {
      NotificationManager.adoptLaunchNotification(
        launchDetails: const NotificationAppLaunchDetails(false),
      );
      NotificationManager.adoptLaunchNotification();

      expect(NotificationManager.pendingRoute, isNull);
      expect(NotificationManager.pendingRouteArguments, isNull);
    });

    test('a later launch source replaces an earlier one completely', () {
      NotificationManager.adoptLaunchNotification(
        initialMessage: RemoteMessage(
          data: {'type': 'SIGNUP_REMINDER', 'signup_id': 's1'},
        ),
        launchDetails: launchedBy('n1'),
      );

      expect(NotificationManager.pendingRoute, Routes.userNotifications);
      expect(NotificationManager.pendingRouteArguments, isNull);
    });
  });
}

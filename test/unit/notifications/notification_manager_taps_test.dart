import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_manager.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

void main() {
  group('NotificationManager taps', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late List<RouteSettings> pushed;

    Future<void> pumpApp(WidgetTester tester) async {
      navigatorKey = GlobalKey<NavigatorState>();
      pushed = [];
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Home')),
          onGenerateRoute: (settings) {
            pushed.add(settings);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(body: Text('At ${settings.name}')),
            );
          },
        ),
      );
    }

    NotificationResponse tap(String? payload) => NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: payload,
    );

    testWidgets('a tap on a shown sign-up reminder opens that sign-up', (
      tester,
    ) async {
      await pumpApp(tester);

      NotificationManager.handleNotificationResponse(
        tap('signup:s1'),
        navigatorKey,
      );
      await tester.pumpAndSettle();

      expect(pushed.single.name, Routes.signupDetail);
      expect(pushed.single.arguments, {'signupId': 's1'});
    });

    testWidgets('a tap on any other shown notification opens the inbox', (
      tester,
    ) async {
      await pumpApp(tester);

      NotificationManager.handleNotificationResponse(tap('n1'), navigatorKey);
      NotificationManager.handleNotificationResponse(tap(null), navigatorKey);
      await tester.pumpAndSettle();

      expect(pushed.map((s) => s.name), [
        Routes.userNotifications,
        Routes.userNotifications,
      ]);
      expect(pushed.every((s) => s.arguments == null), isTrue);
    });

    testWidgets('a tap on a pushed sign-up reminder opens that sign-up', (
      tester,
    ) async {
      await pumpApp(tester);

      NotificationManager.openFromMessage(
        RemoteMessage(
          data: {'type': 'SIGNUP_REMINDER', 'signup_id': 's1', 'slot_id': 'a'},
        ),
        navigatorKey,
      );
      await tester.pumpAndSettle();

      expect(pushed.single.name, Routes.signupDetail);
      expect(pushed.single.arguments, {'signupId': 's1'});
    });

    testWidgets('a tap on any other pushed notification opens the inbox', (
      tester,
    ) async {
      await pumpApp(tester);

      NotificationManager.openFromMessage(
        RemoteMessage(data: {'type': 'TEMPLE_NOTIFICATION'}),
        navigatorKey,
      );
      await tester.pumpAndSettle();

      expect(pushed.single.name, Routes.userNotifications);
    });

    testWidgets('a tap before the app has a navigator is ignored', (
      tester,
    ) async {
      final unattached = GlobalKey<NavigatorState>();

      NotificationManager.handleNotificationResponse(
        tap('signup:s1'),
        unattached,
      );
      NotificationManager.openFromMessage(RemoteMessage(), unattached);
      // (nothing to assert beyond not throwing)
      await tester.pumpWidget(const SizedBox());
    });
  });
}

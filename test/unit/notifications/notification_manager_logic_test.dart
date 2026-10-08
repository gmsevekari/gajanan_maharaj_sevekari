import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_manager.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_routing.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';

void main() {
  group('NotificationManager Logic', () {
    test('consumePendingRoute returns and clears pending route', () {
      NotificationManager.pendingRoute = '/test';
      
      final route = NotificationManager.consumePendingRoute();
      
      expect(route, '/test');
      expect(NotificationManager.pendingRoute, isNull);
    });

    test('isUSRegion should handle null dispatcher locale gracefully', () {
      // In tests, the platform dispatcher may not have a locale set
      // The current implementation defaults to false on errors or if countryCode is null
      final isUS = NotificationManager.isUSRegion();
      expect(isUS, false);
    });
  });

  group('NotificationConstants Logic', () {
    test('getParayanReminderTopic should format correctly', () {
      final topic = NotificationConstants.getParayanReminderTopic('event1', 1);
      expect(topic, 'parayan_event1_day1');
    });
  });

  group('NotificationManager pending route arguments', () {
    test('are returned once and cleared', () {
      NotificationManager.pendingRouteArguments = {'signupId': 's1'};

      expect(NotificationManager.consumePendingRouteArguments(), {
        'signupId': 's1',
      });
      expect(NotificationManager.pendingRouteArguments, isNull);
      expect(NotificationManager.consumePendingRouteArguments(), isNull);
    });
  });

  group('NotificationManager payloadFor', () {
    test('names the sign-up for a sign-up reminder', () {
      final message = RemoteMessage(
        messageId: 'm1',
        data: {
          'type': 'SIGNUP_REMINDER',
          'signup_id': 'sign1',
          'slot_id': 'slotA',
          'notification_id': 'n1',
        },
      );

      expect(NotificationManager.payloadFor(message), 'signup:sign1');
    });

    test('is the notification id for any other notification', () {
      final message = RemoteMessage(
        messageId: 'm1',
        data: {'type': 'TEMPLE_NOTIFICATION', 'notification_id': 'n1'},
      );

      expect(NotificationManager.payloadFor(message), 'n1');
    });

    test('falls back to the message id, then the data id', () {
      expect(
        NotificationManager.payloadFor(RemoteMessage(messageId: 'm1')),
        'm1',
      );
      expect(
        NotificationManager.payloadFor(RemoteMessage(data: {'id': 'd1'})),
        'd1',
      );
    });

    test('a message that merely carries a sign-up id is not a reminder', () {
      final message = RemoteMessage(
        messageId: 'm1',
        data: {'type': 'TEMPLE_NOTIFICATION', 'signup_id': 'sign1'},
      );

      expect(NotificationManager.payloadFor(message), 'm1');
    });

    test('a sign-up reminder with no sign-up uses the usual payload', () {
      final message = RemoteMessage(
        messageId: 'm1',
        data: {'type': 'SIGNUP_REMINDER', 'notification_id': 'n1'},
      );

      expect(NotificationManager.payloadFor(message), 'n1');
    });
  });

  group('NotificationManager setPendingTarget', () {
    tearDown(() {
      NotificationManager.pendingRoute = null;
      NotificationManager.pendingRouteArguments = null;
    });

    test('sets the route and its arguments together', () {
      NotificationManager.setPendingTarget(
        const NotificationTarget('/signup_detail', {'signupId': 's1'}),
      );

      expect(NotificationManager.consumePendingRoute(), '/signup_detail');
      expect(NotificationManager.consumePendingRouteArguments(), {
        'signupId': 's1',
      });
    });

    test('drops an earlier target\'s arguments when the next has none', () {
      NotificationManager.setPendingTarget(
        const NotificationTarget('/signup_detail', {'signupId': 's1'}),
      );

      NotificationManager.setPendingTarget(
        const NotificationTarget(Routes.userNotifications),
      );

      expect(NotificationManager.consumePendingRoute(), Routes.userNotifications);
      expect(NotificationManager.consumePendingRouteArguments(), isNull);
    });
  });
}

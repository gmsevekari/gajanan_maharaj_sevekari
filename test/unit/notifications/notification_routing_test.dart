import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_routing.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

void main() {
  group('forMessageData', () {
    test('sends a sign-up reminder to that sign-up', () {
      final target = NotificationRouting.forMessageData({
        'type': 'SIGNUP_REMINDER',
        'signup_id': 'sign1',
        'slot_id': 'slotA',
      });

      expect(target.route, Routes.signupDetail);
      expect(target.arguments, {'signupId': 'sign1'});
    });

    test('sends a sign-up reminder without a sign-up to the inbox', () {
      for (final data in [
        {'type': 'SIGNUP_REMINDER'},
        {'type': 'SIGNUP_REMINDER', 'signup_id': ''},
        {'type': 'SIGNUP_REMINDER', 'signup_id': null},
      ]) {
        final target = NotificationRouting.forMessageData(data);

        expect(target.route, Routes.userNotifications, reason: '$data');
        expect(target.arguments, isNull);
      }
    });

    test('sends every other notification to the inbox', () {
      for (final data in [
        <String, dynamic>{},
        {'type': 'TEMPLE_NOTIFICATION'},
        {'type': 'PARAYAN_REMINDER', 'event_id': 'e1'},
        {'type': 'TYPO_REPORT'},
        {'signup_id': 'sign1'}, // no type: not a sign-up reminder
      ]) {
        final target = NotificationRouting.forMessageData(data);

        expect(target.route, Routes.userNotifications, reason: '$data');
        expect(target.arguments, isNull);
      }
    });
  });

  group('payload', () {
    test('for a sign-up reminder names the sign-up', () {
      expect(NotificationRouting.payloadForSignup('sign1'), 'signup:sign1');
    });

    test('is turned back into the sign-up\'s page', () {
      final target = NotificationRouting.forPayload('signup:sign1');

      expect(target.route, Routes.signupDetail);
      expect(target.arguments, {'signupId': 'sign1'});
    });

    test('of any other kind, or none, goes to the inbox', () {
      for (final payload in [null, '', 'abc123', 'signup:', 'signup', 'x:y']) {
        final target = NotificationRouting.forPayload(payload);

        expect(target.route, Routes.userNotifications, reason: '$payload');
        expect(target.arguments, isNull);
      }
    });

    test('keeps a sign-up id that has a colon in it', () {
      final target = NotificationRouting.forPayload('signup:a:b');

      expect(target.arguments, {'signupId': 'a:b'});
    });
  });
}

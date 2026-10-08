import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_channels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('which channel a push is shown under', () {
    test('a sign-up reminder uses the sign-up reminders channel', () {
      final details = NotificationChannels.detailsFor({
        'type': 'SIGNUP_REMINDER',
      });

      expect(details.channelId, 'signup_reminders');
      expect(details.channelName, 'Sign-up reminders');
      expect(details.importance, Importance.high);
      expect(details.priority, Priority.high);
    });

    test('anything else keeps the temple notifications channel', () {
      for (final data in [
        <String, dynamic>{},
        {'type': 'TEMPLE_NOTIFICATION'},
        {'type': 'PARAYAN_REMINDER'},
      ]) {
        final details = NotificationChannels.detailsFor(data);

        expect(details.channelId, 'temple_notifications', reason: '$data');
        expect(details.importance, Importance.max);
      }
    });

    test('uses the same channel id as the reminder function', () {
      // functions/signupReminders.js: ANDROID_CHANNEL = "signup_reminders".
      expect(NotificationChannels.signupRemindersId, 'signup_reminders');
    });
  });

  group('creating the sign-up reminders channel', () {
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      FlutterLocalNotificationsPlatform.instance =
          AndroidFlutterLocalNotificationsPlugin();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('registers one high-importance channel with Android', () async {
      await NotificationChannels.createSignupReminders(
        FlutterLocalNotificationsPlugin(),
      );

      final created = calls.where(
        (c) => c.method == 'createNotificationChannel',
      );
      expect(created, hasLength(1));
      final arguments = created.single.arguments as Map<Object?, Object?>;
      expect(arguments['id'], 'signup_reminders');
      expect(arguments['name'], 'Sign-up reminders');
      expect(arguments['importance'], Importance.high.value);
    });

    test('does not create the other channels', () async {
      await NotificationChannels.createSignupReminders(
        FlutterLocalNotificationsPlugin(),
      );

      final ids = calls
          .where((c) => c.method == 'createNotificationChannel')
          .map((c) => (c.arguments as Map<Object?, Object?>)['id']);
      expect(ids, ['signup_reminders']);
    });

    test('does nothing on a platform without channels', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await NotificationChannels.createSignupReminders(
        FlutterLocalNotificationsPlugin(),
      );

      expect(calls, isEmpty);
    });
  });
}

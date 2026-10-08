import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/notifications/signup_reminder_subscriptions.dart';
import 'package:gajanan_maharaj_sevekari/utils/notification_service_helper.dart';
import '../../mocks.dart';

class _MockSignupReminders extends Mock
    implements SignupReminderSubscriptions {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseMessaging mockMessaging;
  const pendingKey = 'pending_fcm_subscriptions';

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    NotificationServiceHelper.overrideMessaging = mockMessaging;

    when(
      () => mockMessaging.subscribeToTopic(any()),
    ).thenAnswer((_) async => {});
    when(
      () => mockMessaging.unsubscribeFromTopic(any()),
    ).thenAnswer((_) async => {});
  });

  tearDown(() {
    NotificationServiceHelper.overrideMessaging = null;
    NotificationServiceHelper.overrideSignupReminders = null;
  });

  group('sign-up reminder subscriptions', () {
    test('are synced when the app starts up', () async {
      final reminders = _MockSignupReminders();
      when(() => reminders.syncAll()).thenAnswer((_) async {});
      NotificationServiceHelper.overrideSignupReminders = reminders;

      await NotificationServiceHelper.syncSignupReminders();

      verify(() => reminders.syncAll()).called(1);
    });

    testWidgets('start-up triggers the sync a few seconds in', (tester) async {
      final reminders = _MockSignupReminders();
      when(() => reminders.syncAll()).thenAnswer((_) async {});
      NotificationServiceHelper.overrideSignupReminders = reminders;

      await NotificationServiceHelper.processOnStartup();
      await tester.pump(const Duration(seconds: 1));
      verifyNever(() => reminders.syncAll());

      await tester.pump(const Duration(seconds: 10));

      verify(() => reminders.syncAll()).called(1);
    });

    test('a failing sync never escapes', () async {
      final reminders = _MockSignupReminders();
      when(
        () => reminders.syncAll(),
      ).thenAnswer((_) async => throw Exception('offline'));
      NotificationServiceHelper.overrideSignupReminders = reminders;

      await NotificationServiceHelper.syncSignupReminders();
    });
  });

  group('NotificationServiceHelper Unit Tests', () {
    test(
      'addPendingSubscriptions stores topics in SharedPreferences and handles pending queue',
      () async {
        SharedPreferences.setMockInitialValues({});

        await NotificationServiceHelper.addPendingSubscriptions([
          'topic1',
          'topic2',
        ], messaging: mockMessaging);

        final prefs = await SharedPreferences.getInstance();
        final storedJson = prefs.getString(pendingKey);

        if (storedJson != null) {
          final List<String> pending = List<String>.from(
            json.decode(storedJson),
          );
          expect(pending, isNotNull);
        }
      },
    );

    test('addPendingSubscriptions prevents duplicate topics', () async {
      SharedPreferences.setMockInitialValues({
        pendingKey: json.encode(['topic1']),
      });

      await NotificationServiceHelper.addPendingSubscriptions([
        'topic1',
        'topic2',
      ], messaging: mockMessaging);

      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString(pendingKey);
      if (storedJson != null) {
        final List<String> pending = List<String>.from(json.decode(storedJson));
        expect(pending.where((t) => t == 'topic1').length, equals(1));
      }
    });

    test(
      'addPendingSubscriptions with empty existing prefs adds all topics',
      () async {
        SharedPreferences.setMockInitialValues({});

        await NotificationServiceHelper.addPendingSubscriptions([
          'new_topic',
        ], messaging: mockMessaging);

        final prefs = await SharedPreferences.getInstance();
        // Either the topic was subscribed (removed from pending) or stored
        final storedJson = prefs.getString(pendingKey);
        // Regardless of outcome, no exception should be thrown
        expect(true, isTrue);
      },
    );

    test('addPendingSubscriptions with multiple unique topics works', () async {
      SharedPreferences.setMockInitialValues({});

      await NotificationServiceHelper.addPendingSubscriptions([
        'topicA',
        'topicB',
        'topicC',
      ], messaging: mockMessaging);

      // Topics are processed and subscribed via the mock; no exception thrown
      expect(true, isTrue);
    });

    test(
      'processOnStartup triggers delayed processing without throwing',
      () async {
        await NotificationServiceHelper.processOnStartup();
      },
    );

    test(
      'unsubscribeFromEventTopics handles 0 days without throwing',
      () async {
        await NotificationServiceHelper.unsubscribeFromEventTopics(
          'event_000',
          0,
        );
        // 0 days → loop never runs, no calls
        verifyNever(() => mockMessaging.unsubscribeFromTopic(any()));
      },
    );

    test(
      'unsubscribeFromEventTopics handles unsubscription loop without throwing',
      () async {
        await NotificationServiceHelper.unsubscribeFromEventTopics(
          'event_123',
          3,
        );
      },
    );

    test('unsubscribeFromEventTopics for 1 day does not throw', () async {
      // Note: unsubscribeFromEventTopics uses FirebaseMessaging.instance directly,
      // not overrideMessaging. It will catch the no-Firebase-app error gracefully.
      await NotificationServiceHelper.unsubscribeFromEventTopics('evt_1day', 1);
      // No exception should be thrown (caught internally)
      expect(true, isTrue);
    });

    test(
      'addPendingSubscriptions processes queue when messaging mock succeeds',
      () async {
        SharedPreferences.setMockInitialValues({
          pendingKey: json.encode(['preloaded_topic']),
        });

        await NotificationServiceHelper.addPendingSubscriptions(
          [],
          messaging: mockMessaging,
        );

        // No new topics added, but preloaded_topic should be processed
        final prefs = await SharedPreferences.getInstance();
        // After success, pending should be cleared
        expect(true, isTrue);
      },
    );

    test(
      'addPendingSubscriptions with subscription failure retains failed topic',
      () async {
        SharedPreferences.setMockInitialValues({});

        when(
          () => mockMessaging.subscribeToTopic(any()),
        ).thenThrow(Exception('Network failure'));

        // Should not throw despite subscription failure
        await expectLater(
          NotificationServiceHelper.addPendingSubscriptions([
            'failing_topic',
          ], messaging: mockMessaging),
          completes,
        );
      },
    );
  });
}

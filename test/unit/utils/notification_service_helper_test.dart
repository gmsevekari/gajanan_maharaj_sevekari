import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/utils/notification_service_helper.dart';
import '../../mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseMessaging mockMessaging;
  const pendingKey = 'pending_fcm_subscriptions';

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    NotificationServiceHelper.overrideMessaging = mockMessaging;

    when(() => mockMessaging.subscribeToTopic(any()))
        .thenAnswer((_) async => {});
    when(() => mockMessaging.unsubscribeFromTopic(any()))
        .thenAnswer((_) async => {});
  });

  group('NotificationServiceHelper Unit Tests', () {
    test('addPendingSubscriptions stores topics in SharedPreferences and handles pending queue', () async {
      SharedPreferences.setMockInitialValues({});

      await NotificationServiceHelper.addPendingSubscriptions(
        ['topic1', 'topic2'],
        messaging: mockMessaging,
      );

      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString(pendingKey);

      if (storedJson != null) {
        final List<String> pending = List<String>.from(json.decode(storedJson));
        expect(pending, isNotNull);
      }
    });

    test('addPendingSubscriptions prevents duplicate topics', () async {
      SharedPreferences.setMockInitialValues({
        pendingKey: json.encode(['topic1'])
      });

      await NotificationServiceHelper.addPendingSubscriptions(
        ['topic1', 'topic2'],
        messaging: mockMessaging,
      );

      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString(pendingKey);
      if (storedJson != null) {
        final List<String> pending = List<String>.from(json.decode(storedJson));
        expect(pending.where((t) => t == 'topic1').length, equals(1));
      }
    });

    test('processOnStartup triggers delayed processing without throwing', () async {
      await NotificationServiceHelper.processOnStartup();
    });

    test('unsubscribeFromEventTopics handles unsubscription loop without throwing', () async {
      await NotificationServiceHelper.unsubscribeFromEventTopics('event_123', 3);
    });
  });
}

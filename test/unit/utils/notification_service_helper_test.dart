import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gajanan_maharaj_sevekari/utils/notification_service_helper.dart';
import '../../mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseMessaging mockMessaging;

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    // Stub the subscribeToTopic call
    when(() => mockMessaging.subscribeToTopic(any()))
        .thenAnswer((_) async => {});
  });

  group('NotificationServiceHelper', () {
    const pendingKey = 'pending_fcm_subscriptions';

    test('addPendingSubscriptions should store topics in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      
      await NotificationServiceHelper.addPendingSubscriptions(
        ['topic1', 'topic2'], 
        messaging: mockMessaging,
      );
      
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString(pendingKey);
      expect(storedJson, isNotNull);
      
      final List<String> pending = List<String>.from(json.decode(storedJson!));
      expect(pending, contains('topic1'));
      expect(pending, contains('topic2'));
    });

    test('addPendingSubscriptions should not add duplicate topics', () async {
      SharedPreferences.setMockInitialValues({
        pendingKey: json.encode(['topic1'])
      });
      
      await NotificationServiceHelper.addPendingSubscriptions(
        ['topic1', 'topic2'],
        messaging: mockMessaging,
      );
      
      final prefs = await SharedPreferences.getInstance();
      final List<String> pending = List<String>.from(json.decode(prefs.getString(pendingKey)!));
      
      expect(pending.length, 2);
      expect(pending, ['topic1', 'topic2']);
    });
  });
}

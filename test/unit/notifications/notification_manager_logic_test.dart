import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_manager.dart';
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
}

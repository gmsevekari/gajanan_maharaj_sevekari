import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationManager Unit Tests', () {
    test('pendingRoute getter and setter work as expected', () {
      NotificationManager.pendingRoute = '/event_calendar';
      expect(NotificationManager.pendingRoute, equals('/event_calendar'));

      NotificationManager.pendingRoute = null;
      expect(NotificationManager.pendingRoute, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/deeplink_manager.dart';

void main() {
  group('DeepLinkManager', () {
    setUp(() {
      // Clear pending state before each test
      DeepLinkManager.consumePendingRoute();
    });

    tearDown(() {
      // Clean up after each test
      DeepLinkManager.consumePendingRoute();
    });

    test('shouldHandle returns true for first-time URI', () {
      final uri = Uri.parse('https://example.com/p/123');
      expect(DeepLinkManager.shouldHandle(uri), true);
    });

    test('shouldHandle returns false for duplicate URI within 1 second', () {
      final uri = Uri.parse('https://example.com/p/123');
      DeepLinkManager.shouldHandle(uri);
      expect(DeepLinkManager.shouldHandle(uri), false);
    });

    test('shouldHandle returns true for different URI', () {
      final uri1 = Uri.parse('https://example.com/p/123');
      final uri2 = Uri.parse('https://example.com/p/456');
      DeepLinkManager.shouldHandle(uri1);
      expect(DeepLinkManager.shouldHandle(uri2), true);
    });

    test('consumePendingRoute returns null when no route set', () {
      expect(DeepLinkManager.consumePendingRoute(), isNull);
    });

    test('hasPendingRoute is true when route is set, false after consumption', () {
      expect(DeepLinkManager.hasPendingRoute, isFalse);
      DeepLinkManager.setPendingRoute('/my-route', null);
      expect(DeepLinkManager.hasPendingRoute, isTrue);
      DeepLinkManager.consumePendingRoute();
      expect(DeepLinkManager.hasPendingRoute, isFalse);
    });

    test('setPendingRoute and consumePendingRoute work correctly', () {
      DeepLinkManager.setPendingRoute('/test', {'id': 1});
      final pending = DeepLinkManager.consumePendingRoute();
      
      expect(pending, isNotNull);
      expect(pending!['route'], '/test');
      expect(pending['arguments'], {'id': 1});
      
      // Should be null after consumption
      expect(DeepLinkManager.consumePendingRoute(), isNull);
    });
  });
}

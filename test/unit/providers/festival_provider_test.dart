import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FestivalProvider Unit Tests', () {
    late FestivalProvider provider;

    setUp(() {
      provider = FestivalProvider();
    });

    test('triggerAnimation sets shouldTriggerAnimation to true and notifies listeners', () {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.triggerAnimation();

      expect(provider.shouldTriggerAnimation, isTrue);
      expect(notified, isTrue);
    });

    test('resetAnimationTrigger resets shouldTriggerAnimation to false', () {
      provider.triggerAnimation();
      expect(provider.shouldTriggerAnimation, isTrue);

      provider.resetAnimationTrigger();
      expect(provider.shouldTriggerAnimation, isFalse);
    });

    test('loadFestivals loads asset and evaluates active festival state', () async {
      await provider.loadFestivals();
      provider.checkActiveFestival();
      // Verifies method execution completes without throwing
      expect(provider.shouldTriggerAnimation, isFalse);
    });
  });
}

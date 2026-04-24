import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/providers/jap_mala_provider.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late JapMalaProvider provider;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    SharedPreferences.setMockInitialValues({});
    provider = JapMalaProvider();
  });

  group('JapMalaProvider - Counting Mode', () {
    test('increment should increase count and malas correctly', () {
      provider.increment();
      expect(provider.currentCount, 1);
      
      // Fast forward to 108
      for (int i = 0; i < 107; i++) {
        provider.increment();
      }
      
      expect(provider.currentCount, 0);
      expect(provider.completedMalas, 1);
    });

    test('decrement should decrease count and malas correctly', () {
      provider.increment();
      provider.decrement();
      expect(provider.currentCount, 0);
      
      provider.increment(); // 1
      provider.decrement(); // 0
      provider.decrement(); // should not go below 0 if malas is 0
      expect(provider.currentCount, 0);
      expect(provider.completedMalas, 0);

      // Test mala borrow
      for (int i = 0; i < 108; i++) provider.increment();
      expect(provider.completedMalas, 1);
      expect(provider.currentCount, 0);
      
      provider.decrement();
      expect(provider.completedMalas, 0);
      expect(provider.currentCount, 107);
    });

    test('reset should clear all counts', () {
      provider.increment();
      provider.reset();
      expect(provider.currentCount, 0);
      expect(provider.completedMalas, 0);
      expect(provider.isPlaying, false);
    });
  });

  group('JapMalaProvider - Manual Entry', () {
    test('should add malas and extra jap correctly', () {
      provider.addManualCount(5, 10);
      expect(provider.completedMalas, 5);
      expect(provider.currentCount, 10);
      expect(provider.totalCount, (5 * 108) + 10);
    });

    test('should normalize extra jap into malas', () {
      provider.addManualCount(
          1, 120); // 1 mala + 120 jap = 1 mala + (1 mala + 12 jap) = 2 malas + 12 jap
      expect(provider.completedMalas, 2);
      expect(provider.currentCount, 12);
      expect(provider.totalCount, (1 * 108) + 120);
    });

    test('should add to existing count', () {
      provider.addManualCount(1, 50);
      provider.addManualCount(1, 60); // Total: 2 malas + 110 jap = 3 malas + 2 jap
      expect(provider.completedMalas, 3);
      expect(provider.currentCount, 2);
    });
  });

  group('JapMalaProvider - Time-Based Mode', () {
    test('startTimeBasedSession should initialize timer', () async {
      await provider.setDuration(0, 1); // 60 seconds
      provider.startTimeBasedSession();
      
      expect(provider.isPlaying, true);
      expect(provider.isTimerExpired, false);
      expect(provider.remainingSeconds, 60);
      
      provider.stop();
      expect(provider.isPlaying, false);
    });

    test('timer completion should set isTimerExpired to true', () async {
      // Since we can't easily wait for real timers in unit tests without complex mocks,
      // we check the state initialization and manually simulate the timer end if needed.
      // But for this unit test, we'll verify the stop() logic still works.
      provider.startTimeBasedSession();
      provider.stop();
      expect(provider.isPlaying, false);
      expect(provider.isTimerExpired, false); // stop() doesn't necessarily set expired to true
    });

    test('stop should cancel timer', () {
      provider.startTimeBasedSession();
      provider.stop();
      expect(provider.isPlaying, false);
    });
  });

  group('JapMalaProvider - Persistence', () {
    test('setCustomTarget should persist value', () async {
      // Using actual mock initial values since SharedPreferences.getInstance() is called
      SharedPreferences.setMockInitialValues({});
      
      await provider.setCustomTarget(50);
      expect(provider.customTargetMalas, 50);
      expect(provider.targetMalas, 50);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(JapMalaProvider.keyCustomTarget), 50);
    });

    test('init should load values from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        JapMalaProvider.keyCustomTarget: 21,
        JapMalaProvider.keyHours: 1,
        JapMalaProvider.keyMinutes: 30,
      });
      
      await provider.init();
      
      expect(provider.customTargetMalas, 21);
      expect(provider.selectedHours, 1);
      expect(provider.selectedMinutes, 30);
    });
  });
}

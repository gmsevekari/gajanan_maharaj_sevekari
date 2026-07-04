import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockVaariService extends Mock implements VaariService {}

void main() {
  late VaariProvider provider;
  late MockVaariService mockService;

  setUp(() {
    registerFallbackValue(
      VaariParticipant(
        memberName: '',
        deviceId: '',
        phone: '',
        joinedAt: DateTime(2000),
        totalSteps: 0,
        totalDistance: 0.0,
      ),
    );
    SharedPreferences.setMockInitialValues({});
    mockService = MockVaariService();
    provider = VaariProvider(service: mockService);
  });

  group('VaariProvider Tests', () {
    test('Initial state is empty', () {
      expect(provider.memberName, isNull);
      expect(provider.phone, isNull);
      expect(provider.hasProfile, false);
      expect(provider.isLoading, false);
    });

    test('loadLocalData updates state from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        VaariProvider.keyMemberName: 'Test Walker',
        VaariProvider.keyPhone: '1234567890',
      });

      await provider.loadLocalData();

      expect(provider.memberName, 'Test Walker');
      expect(provider.phone, '1234567890');
      expect(provider.hasProfile, true);
    });

    test('signUp success updates local storage and state', () async {
      when(
        () => mockService.joinEvent(
          eventId: any(named: 'eventId'),
          joinCode: any(named: 'joinCode'),
          participant: any(named: 'participant'),
        ),
      ).thenAnswer((_) async => true);

      final success = await provider.signUp(
        eventId: 'event_1',
        joinCode: '123456',
        memberName: 'New Walker',
        phone: '9876543210',
        deviceId: 'device_1',
      );

      expect(success, true);
      expect(provider.memberName, 'New Walker');
      expect(provider.phone, '9876543210');
      expect(provider.isJoined('event_1'), true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(VaariProvider.keyMemberName), 'New Walker');
    });

    test('signUp failure does not update local storage or state', () async {
      when(
        () => mockService.joinEvent(
          eventId: any(named: 'eventId'),
          joinCode: any(named: 'joinCode'),
          participant: any(named: 'participant'),
        ),
      ).thenAnswer((_) async => false);

      final success = await provider.signUp(
        eventId: 'event_1',
        joinCode: '000000',
        memberName: 'New Walker',
        phone: '9876543210',
        deviceId: 'device_1',
      );

      expect(success, false);
      expect(provider.memberName, isNull);
      expect(provider.phone, isNull);
      expect(provider.isJoined('event_1'), false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(VaariProvider.keyMemberName), isNull);
    });

    test('syncParticipation updates state if participant found on server', () async {
      final participant = VaariParticipant(
        memberName: 'Remote Walker',
        deviceId: 'device_1',
        phone: '5555555555',
        joinedAt: DateTime(2024),
        totalSteps: 0,
        totalDistance: 0.0,
      );

      when(
        () => mockService.checkParticipation('event_1', 'device_1'),
      ).thenAnswer((_) async => participant);

      await provider.syncParticipation('event_1', 'device_1');

      expect(provider.memberName, 'Remote Walker');
      expect(provider.phone, '5555555555');
      expect(provider.isJoined('event_1'), true);
    });

    test('syncParticipation sets joined to false if participant not found on server', () async {
      when(
        () => mockService.checkParticipation('event_1', 'device_1'),
      ).thenAnswer((_) async => null);

      await provider.syncParticipation('event_1', 'device_1');

      expect(provider.isJoined('event_1'), false);
    });

    test('deleteSignUp calls service and updates state', () async {
      when(
        () => mockService.deleteParticipation(
          eventId: any(named: 'eventId'),
          deviceId: any(named: 'deviceId'),
          memberName: any(named: 'memberName'),
        ),
      ).thenAnswer((_) async {});

      // Setup local profile details first
      SharedPreferences.setMockInitialValues({
        VaariProvider.keyMemberName: 'Test Walker',
        VaariProvider.keyPhone: '1234567890',
      });
      await provider.loadLocalData();

      await provider.deleteSignUp('event_1', 'device_1');
      expect(provider.isJoined('event_1'), false);
    });

    test('deleteSignUp is a no-op when memberName is null', () async {
      // memberName is null (no profile loaded)
      await provider.deleteSignUp('event_1', 'device_1');
      verifyNever(() => mockService.deleteParticipation(
            eventId: any(named: 'eventId'),
            deviceId: any(named: 'deviceId'),
            memberName: any(named: 'memberName'),
          ));
    });
  });
}

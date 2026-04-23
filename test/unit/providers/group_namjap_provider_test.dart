import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGroupNamjapService extends Mock implements GroupNamjapService {}

void main() {
  late GroupNamjapProvider provider;
  late MockGroupNamjapService mockService;

  setUp(() {
    registerFallbackValue(
      GroupNamjapParticipant(
        memberName: '',
        deviceId: '',
        phone: '',
        joinedAt: DateTime.now(),
        totalCount: 0,
      ),
    );
    SharedPreferences.setMockInitialValues({});
    mockService = MockGroupNamjapService();
    provider = GroupNamjapProvider(service: mockService);
  });

  group('GroupNamjapProvider Tests', () {
    test('Initial state is empty', () {
      expect(provider.memberName, isNull);
      expect(provider.phone, isNull);
      expect(provider.hasProfile, false);
      expect(provider.isLoading, false);
    });

    test('loadLocalData updates state from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        GroupNamjapProvider.keyMemberName: 'Test User',
        GroupNamjapProvider.keyPhone: '1234567890',
      });

      await provider.loadLocalData();

      expect(provider.memberName, 'Test User');
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
        memberName: 'New User',
        phone: '9876543210',
        deviceId: 'device_1',
      );

      expect(success, true);
      expect(provider.memberName, 'New User');
      expect(provider.phone, '9876543210');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(GroupNamjapProvider.keyMemberName), 'New User');
    });

    test(
      'syncParticipation updates state if participant found on server',
      () async {
        final participant = GroupNamjapParticipant(
          memberName: 'Remote User',
          deviceId: 'device_1',
          phone: '5555555555',
          joinedAt: DateTime.now(),
          totalCount: 0,
        );

        when(
          () => mockService.checkParticipation('event_1', 'device_1'),
        ).thenAnswer((_) async => participant);

        await provider.syncParticipation('event_1', 'device_1');

        expect(provider.memberName, 'Remote User');
        expect(provider.phone, '5555555555');
        expect(provider.isJoined('event_1'), true);
      },
    );
  });
}

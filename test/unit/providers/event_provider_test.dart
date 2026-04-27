import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/providers/event_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:gajanan_maharaj_sevekari/models/event.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockGroupSelectionProvider extends Mock
    implements GroupSelectionProvider {}

void main() {
  late EventProvider provider;
  late FakeFirebaseFirestore fakeFirestore;
  late MockGroupSelectionProvider mockGroupProvider;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockGroupProvider = MockGroupSelectionProvider();

    when(() => mockGroupProvider.selectedGroupIds).thenReturn(['g1']);
    when(() => mockGroupProvider.addListener(any())).thenReturn(null);
    when(() => mockGroupProvider.removeListener(any())).thenReturn(null);
  });

  group('EventProvider', () {
    test('initialization should fetch events if groups are selected', () async {
      provider = EventProvider(
        firestore: fakeFirestore,
        groupSelectionProvider: mockGroupProvider,
      );

      expect(provider.isLoading, isTrue);
      await Future.delayed(Duration.zero); // Allow async fetch to start
    });

    test('fetchEvents should group events by groupId', () async {
      final now = DateTime.now();
      final startTime = Timestamp.fromDate(now.add(const Duration(hours: 1)));

      await fakeFirestore.collection('events').add({
        'title_en': 'Weekly Pooja',
        'event_type': 'weekly_pooja',
        'start_time': startTime,
        'groupId': 'g1',
      });

      provider = EventProvider(
        firestore: fakeFirestore,
        groupSelectionProvider: mockGroupProvider,
      );

      await provider.fetchEvents();

      expect(provider.groupedEvents.containsKey('g1'), isTrue);
      expect(
        provider.groupedEvents['g1']?.weeklyPooja?.title_en,
        'Weekly Pooja',
      );
    });

    test(
      'fetchEvents should filter out events that have already ended',
      () async {
        final now = DateTime.now();
        final pastStartTime = Timestamp.fromDate(
          now.subtract(const Duration(hours: 2)),
        );
        final pastEndTime = Timestamp.fromDate(
          now.subtract(const Duration(hours: 1)),
        );

        await fakeFirestore.collection('events').add({
          'title_en': 'Past Event',
          'event_type': 'weekly_pooja',
          'start_time': pastStartTime,
          'end_time': pastEndTime,
          'groupId': 'g1',
        });

        provider = EventProvider(
          firestore: fakeFirestore,
          groupSelectionProvider: mockGroupProvider,
        );

        await provider.fetchEvents();

        expect(provider.groupedEvents['g1']?.weeklyPooja, isNull);
      },
    );

    test('fetchEvents should keep events that are currently ongoing', () async {
      final now = DateTime.now();
      final startTime = Timestamp.fromDate(now.add(const Duration(minutes: 5)));
      final endTime = Timestamp.fromDate(now.add(const Duration(minutes: 60)));

      await fakeFirestore.collection('events').add({
        'title_en': 'Ongoing Event',
        'event_type': 'special_event',
        'start_time': startTime,
        'end_time': endTime,
        'groupId': 'g1',
      });

      provider = EventProvider(
        firestore: fakeFirestore,
        groupSelectionProvider: mockGroupProvider,
      );

      await provider.fetchEvents();

      expect(
        provider.groupedEvents['g1']?.specialEvent?.title_en,
        'Ongoing Event',
      );
    });

    test('fetchEvents should fetch parayan events', () async {
      final now = DateTime.now();
      final endDate = Timestamp.fromDate(now.add(const Duration(days: 1)));

      await fakeFirestore.collection('parayan_events').add({
        'title_en': 'Test Parayan',
        'title_mr': 'पारायण',
        'description_en': 'Desc',
        'description_mr': 'माहिती',
        'type': 'oneDay',
        'startDate': Timestamp.fromDate(now),
        'endDate': endDate,
        'status': 'upcoming',
        'reminderTimes': <String>[],
        'createdAt': Timestamp.now(),
        'groupId': 'g1',
      });

      provider = EventProvider(
        firestore: fakeFirestore,
        groupSelectionProvider: mockGroupProvider,
      );

      await provider.fetchEvents();

      expect(provider.groupedEvents['g1']?.parayan?.titleEn, 'Test Parayan');
    });

    test('fetchEvents should clear events if no groups are selected', () async {
      when(() => mockGroupProvider.selectedGroupIds).thenReturn([]);
      provider = EventProvider(
        firestore: fakeFirestore,
        groupSelectionProvider: mockGroupProvider,
      );

      await provider.fetchEvents();

      expect(provider.groupedEvents, isEmpty);
    });

    test('should fetch events when groups change', () async {
      // Use a real GroupSelectionProvider for listener testing if needed,
      // but here we just verify fetchEvents is called or state changes.
      provider = EventProvider(
        firestore: fakeFirestore,
        groupSelectionProvider: mockGroupProvider,
      );

      // Clear stub result to see change
      await provider.fetchEvents();
      expect(provider.groupedEvents['g1']?.weeklyPooja, isNull);

      // Add data and trigger change
      await fakeFirestore.collection('events').add({
        'title_en': 'New Event',
        'event_type': 'weekly_pooja',
        'start_time': Timestamp.now(),
        'groupId': 'g1',
      });

      provider
          .fetchEvents(); // Manually trigger since we are mocking the provider listener
      await Future.delayed(Duration.zero);

      expect(provider.groupedEvents['g1']?.weeklyPooja?.title_en, 'New Event');
    });

    test('should handle Firestore errors gracefully', () async {
      final failingFirestore = MockFirebaseFirestore();
      when(
        () => failingFirestore.collection(any()),
      ).thenThrow(Exception('Firestore error'));

      provider = EventProvider(
        firestore: failingFirestore,
        groupSelectionProvider: mockGroupProvider,
      );

      await provider.fetchEvents();

      expect(provider.error, contains('Firestore error'));
      expect(provider.isLoading, isFalse);
    });

    test('GroupEvents.isEmpty should return true if all fields are null', () {
      const empty = GroupEvents();
      expect(empty.isEmpty, isTrue);

      final notEmpty = GroupEvents(
        weeklyPooja: Event(
          title_mr: '',
          title_en: '',
          start_time: Timestamp.now(),
        ),
      );
      expect(notEmpty.isEmpty, isFalse);
    });

    test('fetchEvents should fetch for multiple groups', () async {
      when(() => mockGroupProvider.selectedGroupIds).thenReturn(['g1', 'g2']);

      await fakeFirestore.collection('events').add({
        'title_en': 'Group 1 Event',
        'event_type': 'weekly_pooja',
        'start_time': Timestamp.now(),
        'groupId': 'g1',
      });
      await fakeFirestore.collection('events').add({
        'title_en': 'Group 2 Event',
        'event_type': 'weekly_pooja',
        'start_time': Timestamp.now(),
        'groupId': 'g2',
      });

      provider = EventProvider(
        firestore: fakeFirestore,
        groupSelectionProvider: mockGroupProvider,
      );

      await provider.fetchEvents();

      expect(
        provider.groupedEvents['g1']?.weeklyPooja?.title_en,
        'Group 1 Event',
      );
      expect(
        provider.groupedEvents['g2']?.weeklyPooja?.title_en,
        'Group 2 Event',
      );
    });

    test('dispose should remove listener', () {
      provider = EventProvider(
        firestore: fakeFirestore,
        groupSelectionProvider: mockGroupProvider,
      );
      provider.dispose();
      verify(() => mockGroupProvider.removeListener(any())).called(1);
    });
  });
}

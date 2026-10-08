import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:gajanan_maharaj_sevekari/notifications/signup_reminder_subscriptions.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMessaging extends Mock implements FirebaseMessaging {}

void main() {
  const myDevice = 'device_me';
  final now = DateTime.utc(2026, 10, 8, 12);

  late FakeFirebaseFirestore firestore;
  late SignupService service;
  late MockMessaging messaging;
  late SignupReminderSubscriptions reminders;

  SignupReminderSubscriptions remindersFor(
    SignupService signupService, {
    DateTime? at,
    String device = myDevice,
  }) => SignupReminderSubscriptions(
    signupService: signupService,
    deviceId: () async => device,
    messaging: messaging,
    now: () => at ?? now,
    timeout: const Duration(milliseconds: 50),
    readTimeout: const Duration(milliseconds: 500),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
    messaging = MockMessaging();
    when(() => messaging.subscribeToTopic(any())).thenAnswer((_) async {});
    when(() => messaging.unsubscribeFromTopic(any())).thenAnswer((_) async {});
    reminders = remindersFor(service);
  });

  Future<String> addSignup() => service.createSignup(
    Signup(
      titleEn: 'Prasad Seva',
      titleMr: '',
      groupId: 'g',
      status: SignupStatus.published,
      createdAt: now,
      updatedAt: now,
      createdBy: 'admin@test.com',
    ),
  );

  SignupSlot slotAt(int? days, {String? id}) => SignupSlot(
    id: id,
    labelEn: 'Slot',
    labelMr: '',
    startAt: days == null ? null : now.add(Duration(days: days)),
    endAt: days == null ? null : now.add(Duration(days: days, hours: 2)),
    timezone: 'America/Los_Angeles',
    capacity: 5,
    sortOrder: 0,
    createdAt: now,
  );

  /// A slot [days] from [now], or with no schedule when [days] is null.
  Future<String> addSlot(String signupId, {int? days = 3}) =>
      service.addSlot(signupId, slotAt(days));

  Future<String> signUp(
    String signupId,
    String slotId, {
    String? deviceId = myDevice,
    String name = 'Asha',
  }) async {
    final result = await service.claimSlot(
      signupId: signupId,
      slotId: slotId,
      name: name,
      deviceId: deviceId,
    );
    return result['entryId'] as String;
  }

  String topic(String signupId, String slotId) =>
      'signup_slot_${signupId}_$slotId';

  void expectSubscribed(String signupId, String slotId, [int times = 1]) =>
      verify(
        () => messaging.subscribeToTopic(topic(signupId, slotId)),
      ).called(times);

  void expectUnsubscribed(String signupId, String slotId, [int times = 1]) =>
      verify(
        () => messaging.unsubscribeFromTopic(topic(signupId, slotId)),
      ).called(times);

  Future<List<String>> staleTopics() async =>
      (await SharedPreferences.getInstance()).getStringList(
        'signup_reminder_stale',
      ) ??
      const [];

  group('the topic name', () {
    test('is one per slot, matching the server', () {
      // The same vector as functions/test/signupReminders.test.js.
      expect(
        NotificationConstants.getSignupSlotReminderTopic('sign1', 'slotA'),
        'signup_slot_sign1_slotA',
      );
    });
  });

  group('syncSignup', () {
    test('subscribes to the slot a device signed up for', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);

      await reminders.syncSignup(signupId);

      expectSubscribed(signupId, slotId);
    });

    test('subscribes to every slot the device signed up for', () async {
      final signupId = await addSignup();
      final a = await addSlot(signupId);
      final b = await addSlot(signupId, days: 5);
      await signUp(signupId, a);
      await signUp(signupId, b, name: 'Bina');

      await reminders.syncSignup(signupId);

      expectSubscribed(signupId, a);
      expectSubscribed(signupId, b);
    });

    test('subscribes only to the slots the device has an entry on', () async {
      final signupId = await addSignup();
      final mine = await addSlot(signupId);
      final notMine = await addSlot(signupId, days: 5);
      await signUp(signupId, mine);
      await signUp(signupId, notMine, deviceId: 'someone_else');

      await reminders.syncSignup(signupId);

      expectSubscribed(signupId, mine);
      verifyNever(() => messaging.subscribeToTopic(topic(signupId, notMine)));
    });

    test(
      'lets go of a sign-up with no entries without reading its slots',
      () async {
        final signupId = await addSignup();
        final slotId = await addSlot(signupId);
        final entryId = await signUp(signupId, slotId);
        await reminders.syncSignup(signupId);
        await service.cancelEntry(signupId, entryId);
        final noSlots = remindersFor(
          _FlakySlotsService(firestore, failFor: signupId),
        );

        await noSlots.syncSignup(signupId); // would throw if it read the slots

        expectUnsubscribed(signupId, slotId);
      },
    );

    test('does nothing for a slot only other devices signed up for', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId, deviceId: 'someone_else');

      await reminders.syncSignup(signupId);

      verifyNever(() => messaging.subscribeToTopic(any()));
    });

    test('never subscribes the admin\'s phone for an entry they add for '
        'someone', () async {
      // adminAddEntry writes no device, and the admin's phone has none on it.
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await service.adminAddEntry(
        signupId: signupId,
        slotId: slotId,
        name: 'Phoned in',
        phone: '14255550100',
      );
      final adminPhone = remindersFor(service, device: 'admin_device');

      await adminPhone.syncSignup(signupId);
      await adminPhone.syncAll();

      verifyNever(() => messaging.subscribeToTopic(any()));
    });

    test('does nothing for a slot that has already finished', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId, days: -3);
      await signUp(signupId, slotId);

      await reminders.syncSignup(signupId);

      verifyNever(() => messaging.subscribeToTopic(any()));
    });

    test('does nothing for a slot with no date and time', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId, days: null);
      await signUp(signupId, slotId);

      await reminders.syncSignup(signupId);

      verifyNever(() => messaging.subscribeToTopic(any()));
    });

    test('unsubscribes once the device cancels its entry', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      final entryId = await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);

      await service.cancelEntry(signupId, entryId);
      await reminders.syncSignup(signupId);

      expectUnsubscribed(signupId, slotId);
      expect(await staleTopics(), isEmpty);
    });

    test(
      'stays subscribed while the device has another entry on the slot',
      () async {
        final signupId = await addSignup();
        final slotId = await addSlot(signupId);
        final first = await signUp(signupId, slotId);
        await signUp(signupId, slotId, name: 'Bina');
        await reminders.syncSignup(signupId);

        await service.cancelEntry(signupId, first);
        await reminders.syncSignup(signupId);

        verifyNever(() => messaging.unsubscribeFromTopic(any()));
      },
    );

    test('unsubscribes when an admin takes the entry off the device', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      final entryId = await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);

      await service.releaseEntryDevice(signupId, entryId);
      await reminders.syncSignup(signupId);

      expectUnsubscribed(signupId, slotId);
    });

    test('leaves other sign-ups alone', () async {
      final one = await addSignup();
      final two = await addSignup();
      final slotOne = await addSlot(one);
      final slotTwo = await addSlot(two);
      await signUp(one, slotOne);
      await signUp(two, slotTwo);
      await reminders.syncSignup(one);
      await reminders.syncSignup(two);

      final entries = await service.getEntriesByDevice(one, myDevice).first;
      await service.cancelEntry(one, entries.single.id!);
      await reminders.syncSignup(one);

      expectUnsubscribed(one, slotOne);
      verifyNever(() => messaging.unsubscribeFromTopic(topic(two, slotTwo)));
    });

    test('keeps two sign-ups apart even if their slots share an id', () async {
      final one = await addSignup();
      final two = await addSignup();
      await service.addSlot(one, slotAt(3, id: 'same'));
      await firestore
          .collection('signups')
          .doc(one)
          .collection('slots')
          .doc('same')
          .set(slotDoc(3));
      await firestore
          .collection('signups')
          .doc(two)
          .collection('slots')
          .doc('same')
          .set(slotDoc(3));
      await signUp(one, 'same');

      await reminders.syncSignup(one);
      await reminders.syncSignup(two);

      expectSubscribed(one, 'same');
      verifyNever(() => messaging.subscribeToTopic(topic(two, 'same')));
    });
  });

  group('when reminders are switched off', () {
    test('records the slots but subscribes to nothing', () async {
      SharedPreferences.setMockInitialValues({
        NotificationConstants.signupRemindersPrefKey: false,
      });
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);

      await reminders.syncSignup(signupId);

      verifyNever(() => messaging.subscribeToTopic(any()));
      await reminders.setEnabled(true);
      expectSubscribed(signupId, slotId);
    });

    test('turning them off unsubscribes from everything', () async {
      final signupId = await addSignup();
      final a = await addSlot(signupId);
      final b = await addSlot(signupId, days: 5);
      await signUp(signupId, a);
      await signUp(signupId, b, name: 'Bina');
      await reminders.syncSignup(signupId);

      await reminders.setEnabled(false);

      expectUnsubscribed(signupId, a);
      expectUnsubscribed(signupId, b);
      expect(await SignupReminderSubscriptions.isEnabled(), isFalse);
    });

    test('turning them back on subscribes again', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);
      await reminders.setEnabled(false);
      clearInteractions(messaging);

      await reminders.setEnabled(true);

      expectSubscribed(signupId, slotId);
      expect(await SignupReminderSubscriptions.isEnabled(), isTrue);
    });

    test(
      'turning them back on skips a slot that has finished meanwhile',
      () async {
        final signupId = await addSignup();
        final slotId = await addSlot(signupId);
        await signUp(signupId, slotId);
        await reminders.syncSignup(signupId);
        await reminders.setEnabled(false);
        clearInteractions(messaging);
        final later = remindersFor(
          service,
          at: now.add(const Duration(days: 10)),
        );

        await later.setEnabled(true);

        expectUnsubscribed(signupId, slotId); // let go of, not renewed
        expect(await staleTopics(), isEmpty);
      },
    );

    test('are on unless the devotee turned them off', () async {
      expect(await SignupReminderSubscriptions.isEnabled(), isTrue);
    });
  });

  group('when the network misbehaves', () {
    test('a failed subscription is retried by the next sync', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);
      when(
        () => messaging.subscribeToTopic(any()),
      ).thenThrow(Exception('offline'));
      await reminders.syncSignup(signupId); // does not throw

      when(() => messaging.subscribeToTopic(any())).thenAnswer((_) async {});
      clearInteractions(messaging);
      await reminders.syncAll();

      expectSubscribed(signupId, slotId);
    });

    test('a subscription that hangs gives up, and is retried by the next '
        'sync', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);
      when(
        () => messaging.subscribeToTopic(any()),
      ).thenAnswer((_) => Completer<void>().future);
      await reminders.syncSignup(signupId).timeout(const Duration(seconds: 5));

      when(() => messaging.subscribeToTopic(any())).thenAnswer((_) async {});
      clearInteractions(messaging);
      await reminders.syncAll();

      expectSubscribed(signupId, slotId);
    });

    test('a failed unsubscription is retried by the next sync', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      final entryId = await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);
      await service.cancelEntry(signupId, entryId);
      when(
        () => messaging.unsubscribeFromTopic(any()),
      ).thenThrow(Exception('offline'));
      await reminders.syncSignup(signupId); // does not throw
      expect(await staleTopics(), [topic(signupId, slotId)]);

      when(
        () => messaging.unsubscribeFromTopic(any()),
      ).thenAnswer((_) async {});
      clearInteractions(messaging);
      await reminders.syncAll();

      expectUnsubscribed(signupId, slotId);
      expect(await staleTopics(), isEmpty);
      clearInteractions(messaging);
      await reminders.syncAll();
      verifyNever(() => messaging.unsubscribeFromTopic(any())); // done with
    });

    test('an unsubscription that hangs gives up, and is retried', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      final entryId = await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);
      await service.cancelEntry(signupId, entryId);
      when(
        () => messaging.unsubscribeFromTopic(any()),
      ).thenAnswer((_) => Completer<void>().future);
      await reminders.syncSignup(signupId).timeout(const Duration(seconds: 5));
      expect(await staleTopics(), [topic(signupId, slotId)]);

      when(
        () => messaging.unsubscribeFromTopic(any()),
      ).thenAnswer((_) async {});
      clearInteractions(messaging);
      await reminders.syncAll();

      expectUnsubscribed(signupId, slotId);
    });

    test('a failed unsubscription is not repeated if the devotee signs up '
        'for that slot again', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      final entryId = await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);
      await service.cancelEntry(signupId, entryId);
      when(
        () => messaging.unsubscribeFromTopic(any()),
      ).thenThrow(Exception('offline'));
      await reminders.syncSignup(signupId); // leaves the topic marked stale

      await signUp(signupId, slotId, name: 'Asha again');
      await reminders.syncSignup(signupId);
      when(
        () => messaging.unsubscribeFromTopic(any()),
      ).thenAnswer((_) async {});
      clearInteractions(messaging);
      await reminders.syncAll();

      verifyNever(() => messaging.unsubscribeFromTopic(any()));
      expectSubscribed(signupId, slotId);
    });

    test('a server that cannot be reached changes nothing', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);
      final offline = remindersFor(_OfflineService(firestore));
      clearInteractions(messaging);

      await expectLater(offline.syncSignup(signupId), throwsException);
      await offline.syncAll(); // does not throw

      verifyNever(() => messaging.unsubscribeFromTopic(any()));
      // Nothing was forgotten: a working sync still finds the slot.
      await reminders.syncAll();
      expectSubscribed(signupId, slotId);
    });

    test('a read that hangs gives up rather than block everything', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);
      final hanging = remindersFor(_HangingService(firestore));

      await expectLater(
        hanging.syncSignup(signupId),
        throwsA(isA<TimeoutException>()),
      );

      await reminders.syncSignup(signupId); // the queue moved on
      expectSubscribed(signupId, slotId);
    });

    test('a slot read that hangs gives up too', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);
      final hanging = remindersFor(_HangingSlotsService(firestore));

      await expectLater(
        hanging.syncSignup(signupId),
        throwsA(isA<TimeoutException>()),
      );
      await hanging.syncAll().timeout(const Duration(seconds: 5));

      verifyNever(() => messaging.subscribeToTopic(any()));
    });

    test('a search across sign-ups that hangs gives up, and the sign-ups '
        'already known are checked one by one', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      final entryId = await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);
      await service.cancelEntry(signupId, entryId);
      final hanging = remindersFor(_HangingDiscoveryService(firestore));
      clearInteractions(messaging);

      await hanging.syncAll().timeout(const Duration(seconds: 5));

      expectUnsubscribed(signupId, slotId);
    });

    test('one sign-up that cannot be read does not stop the others', () async {
      final one = await addSignup();
      final two = await addSignup();
      final slotOne = await addSlot(one);
      final slotTwo = await addSlot(two);
      await signUp(one, slotOne);
      await signUp(two, slotTwo, name: 'Bina');
      final flaky = remindersFor(_FlakySlotsService(firestore, failFor: one));

      await flaky.syncAll();

      verifyNever(() => messaging.subscribeToTopic(topic(one, slotOne)));
      expectSubscribed(two, slotTwo);
    });

    test('checks the known sign-ups one by one when it cannot look across '
        'them', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      final entryId = await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);
      await service.cancelEntry(signupId, entryId);
      final noDiscovery = remindersFor(_NoDiscoveryService(firestore));
      clearInteractions(messaging);

      await noDiscovery.syncAll();

      expectUnsubscribed(signupId, slotId);
    });
  });

  group('syncAll', () {
    test('keeps and renews the subscriptions that are still valid', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);
      clearInteractions(messaging);

      await reminders.syncAll();

      expectSubscribed(signupId, slotId);
      verifyNever(() => messaging.unsubscribeFromTopic(any()));
    });

    test('lets go of a slot that has since finished', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);
      final later = remindersFor(
        service,
        at: now.add(const Duration(days: 10)),
      );

      await later.syncAll();

      expectUnsubscribed(signupId, slotId);
    });

    test('lets go of everything for a sign-up that was deleted', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);

      await firestore.collection('signups').doc(signupId).delete();
      for (final collection in ['slots', 'entries']) {
        final docs = await firestore
            .collection('signups')
            .doc(signupId)
            .collection(collection)
            .get();
        for (final doc in docs.docs) {
          await doc.reference.delete();
        }
      }
      await reminders.syncAll();

      expectUnsubscribed(signupId, slotId);
    });

    test('never throws, even if the device cannot be identified', () async {
      final unnamed = SignupReminderSubscriptions(
        signupService: service,
        deviceId: () async => throw Exception('no id'),
        messaging: messaging,
        now: () => now,
      );

      await unnamed.syncAll(); // does not throw
    });

    test('does nothing at all for a device that never signed up', () async {
      await reminders.syncAll();

      verifyNever(() => messaging.subscribeToTopic(any()));
      verifyNever(() => messaging.unsubscribeFromTopic(any()));
    });

    test('finds sign-ups made before the app kept track (or before a '
        'reinstall)', () async {
      // The entries are on this device's id, but nothing is stored locally.
      final one = await addSignup();
      final two = await addSignup();
      final slotOne = await addSlot(one);
      final slotTwo = await addSlot(two, days: 6);
      await signUp(one, slotOne);
      await signUp(two, slotTwo, name: 'Bina');
      SharedPreferences.setMockInitialValues({});

      await reminders.syncAll();

      expectSubscribed(one, slotOne);
      expectSubscribed(two, slotTwo);
    });

    test('picks up a slot that was given its date after the sign-up', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId, days: null);
      await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);
      verifyNever(() => messaging.subscribeToTopic(any()));

      await service.updateSlot(signupId, slotAt(4, id: slotId));
      await reminders.syncAll();

      expectSubscribed(signupId, slotId);
    });

    test('leaves other devices\' entries alone', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId, deviceId: 'someone_else');

      await reminders.syncAll();

      verifyNever(() => messaging.subscribeToTopic(any()));
    });
  });

  group('keeping its books straight', () {
    test('a topic is on the stale list before it is let go of', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      final entryId = await signUp(signupId, slotId);
      await reminders.syncSignup(signupId);
      await service.cancelEntry(signupId, entryId);
      List<String>? duringUnsubscribe;
      when(() => messaging.unsubscribeFromTopic(any())).thenAnswer((_) async {
        duringUnsubscribe = await staleTopics();
      });

      await reminders.syncSignup(signupId);

      // If the app were killed right here, the next start still knows.
      expect(duringUnsubscribe, [topic(signupId, slotId)]);
      expect(await staleTopics(), isEmpty);
    });

    test('overlapping syncs run one after the other, never together', () async {
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      final entryId = await signUp(signupId, slotId);
      final events = <String>[];
      final subscribing = Completer<void>();
      when(() => messaging.subscribeToTopic(any())).thenAnswer((_) async {
        events.add('subscribe');
        await subscribing.future;
        events.add('subscribed');
      });
      when(() => messaging.unsubscribeFromTopic(any())).thenAnswer((_) async {
        events.add('unsubscribe');
      });
      // The first sync waits on its subscription longer than the short
      // timeout the other tests use.
      final patient = SignupReminderSubscriptions(
        signupService: _RecordingService(firestore, events),
        deviceId: () async => myDevice,
        messaging: messaging,
        now: () => now,
        timeout: const Duration(seconds: 5),
      );

      final first = patient.syncSignup(signupId);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await service.cancelEntry(signupId, entryId);
      final second = patient.syncSignup(signupId);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      subscribing.complete();
      await Future.wait([first, second]);

      // The second sync reads only after the first has finished.
      expect(events, [
        'read',
        'subscribe',
        'subscribed',
        'read',
        'unsubscribe',
      ]);
    });

    test(
      'overlapping syncs take turns, so the later one has the last word',
      () async {
        final signupId = await addSignup();
        final slotId = await addSlot(signupId);
        final entryId = await signUp(signupId, slotId);
        final subscribing = Completer<void>();
        when(
          () => messaging.subscribeToTopic(any()),
        ).thenAnswer((_) => subscribing.future);

        // A claim's sync is still subscribing when the devotee cancels.
        final first = reminders.syncSignup(signupId);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await service.cancelEntry(signupId, entryId);
        final second = reminders.syncSignup(signupId);
        subscribing.complete();
        await Future.wait([first, second]);

        expectUnsubscribed(signupId, slotId);
        clearInteractions(messaging);
        await reminders.syncAll();
        verifyNever(() => messaging.subscribeToTopic(any()));
      },
    );

    test('an unreadable list of slots is dropped, not fatal', () async {
      SharedPreferences.setMockInitialValues({
        'signup_reminder_wanted': 'this is not json',
      });
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);

      await reminders.syncAll();

      expectSubscribed(signupId, slotId);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('signup_reminder_wanted'), contains(slotId));
    });

    test(
      'an unreadable list is cleared even if nothing can be rebuilt',
      () async {
        SharedPreferences.setMockInitialValues({
          'signup_reminder_wanted': 'this is not json',
        });
        final signupId = await addSignup();
        final offline = remindersFor(_OfflineService(firestore));

        await offline.syncAll();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('signup_reminder_wanted'), isFalse);
        expect(signupId, isNotEmpty);
      },
    );

    test('a list of the wrong shape is dropped too', () async {
      SharedPreferences.setMockInitialValues({
        'signup_reminder_wanted': '{"unexpected": 1}',
      });
      final signupId = await addSignup();
      final slotId = await addSlot(signupId);
      await signUp(signupId, slotId);

      await reminders.syncAll();

      expectSubscribed(signupId, slotId);
    });
  });
}

/// A slot document, as the database stores it.
Map<String, dynamic> slotDoc(int days) {
  final start = DateTime.utc(2026, 10, 8, 12).add(Duration(days: days));
  return SignupSlot(
    labelEn: 'Slot',
    labelMr: '',
    startAt: start,
    endAt: start.add(const Duration(hours: 2)),
    timezone: 'America/Los_Angeles',
    capacity: 5,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 10, 8, 12),
  ).toMap();
}

/// A service whose server can't be reached: every fresh read fails.
class _OfflineService extends SignupService {
  _OfflineService(FakeFirebaseFirestore firestore)
    : super(firestore: firestore);

  @override
  Future<List<SignupEntry>> fetchEntriesByDevice(
    String signupId,
    String deviceId,
  ) => Future.error(Exception('offline'));

  @override
  Future<List<SignupSlot>> fetchSlots(String signupId) =>
      Future.error(Exception('offline'));

  @override
  Future<List<({String signupId, SignupEntry entry})>> fetchEntriesForDevice(
    String deviceId,
  ) => Future.error(Exception('offline'));
}

/// A service whose reads never answer.
class _HangingService extends SignupService {
  _HangingService(FakeFirebaseFirestore firestore)
    : super(firestore: firestore);

  @override
  Future<List<SignupEntry>> fetchEntriesByDevice(
    String signupId,
    String deviceId,
  ) => Completer<List<SignupEntry>>().future;
}

/// A service that can't look across sign-ups (as when the index or rule for
/// that is not deployed yet) but reads one sign-up fine.
class _NoDiscoveryService extends SignupService {
  _NoDiscoveryService(FakeFirebaseFirestore firestore)
    : super(firestore: firestore);

  @override
  Future<List<({String signupId, SignupEntry entry})>> fetchEntriesForDevice(
    String deviceId,
  ) => Future.error(Exception('permission-denied'));
}

/// A service whose slot reads never answer.
class _HangingSlotsService extends SignupService {
  _HangingSlotsService(FakeFirebaseFirestore firestore)
    : super(firestore: firestore);

  @override
  Future<List<SignupSlot>> fetchSlots(String signupId) =>
      Completer<List<SignupSlot>>().future;
}

/// A service whose search across sign-ups never answers.
class _HangingDiscoveryService extends SignupService {
  _HangingDiscoveryService(FakeFirebaseFirestore firestore)
    : super(firestore: firestore);

  @override
  Future<List<({String signupId, SignupEntry entry})>> fetchEntriesForDevice(
    String deviceId,
  ) => Completer<List<({String signupId, SignupEntry entry})>>().future;
}

/// A service that can't read the slots of one sign-up.
class _FlakySlotsService extends SignupService {
  final String failFor;

  _FlakySlotsService(FakeFirebaseFirestore firestore, {required this.failFor})
    : super(firestore: firestore);

  @override
  Future<List<SignupSlot>> fetchSlots(String signupId) => signupId == failFor
      ? Future.error(Exception('offline'))
      : super.fetchSlots(signupId);
}

/// A service that notes every read of a device's entries.
class _RecordingService extends SignupService {
  final List<String> events;

  _RecordingService(FakeFirebaseFirestore firestore, this.events)
    : super(firestore: firestore);

  @override
  Future<List<SignupEntry>> fetchEntriesByDevice(
    String signupId,
    String deviceId,
  ) {
    events.add('read');
    return super.fetchEntriesByDevice(signupId, deviceId);
  }
}

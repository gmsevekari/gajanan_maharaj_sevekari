import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_participant.dart';

class VaariService extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  VaariService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String eventsCollection = 'vaari_events';
  static const String participantsSubcollection = 'participants';

  Stream<List<VaariEvent>> getActiveEvents(String groupId) {
    throw UnimplementedError();
  }

  Stream<List<VaariEvent>> getCompletedEvents(String groupId) {
    throw UnimplementedError();
  }

  Stream<VaariEvent?> getEventStream(String eventId) {
    throw UnimplementedError();
  }

  Stream<VaariParticipant?> getParticipantStream(
    String eventId,
    String deviceId,
    String memberName,
  ) {
    throw UnimplementedError();
  }

  Stream<int> getParticipantsCountStream(String eventId) {
    throw UnimplementedError();
  }

  Future<void> createEvent(VaariEvent event) async {
    throw UnimplementedError();
  }

  Future<bool> joinEvent({
    required String eventId,
    required String joinCode,
    required VaariParticipant participant,
  }) async {
    throw UnimplementedError();
  }

  Future<void> submitSteps({
    required String eventId,
    required String deviceId,
    required String memberName,
    required int stepsToSubmit,
    double? distanceToSubmit,
  }) async {
    throw UnimplementedError();
  }

  Future<VaariParticipant?> checkParticipation(
    String eventId,
    String deviceId,
  ) async {
    throw UnimplementedError();
  }

  Future<void> deleteParticipation({
    required String eventId,
    required String deviceId,
    required String memberName,
  }) async {
    throw UnimplementedError();
  }
}

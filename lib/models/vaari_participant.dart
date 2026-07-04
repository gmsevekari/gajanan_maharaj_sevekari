import 'package:cloud_firestore/cloud_firestore.dart';

class VaariParticipant {
  final String memberName;
  final String deviceId;
  final String phone;
  final DateTime joinedAt;
  final int totalSteps;
  final double totalDistance;

  VaariParticipant({
    required this.memberName,
    required this.deviceId,
    required this.phone,
    required this.joinedAt,
    required this.totalSteps,
    required this.totalDistance,
  });

  factory VaariParticipant.fromMap(Map<String, dynamic> data) {
    throw UnimplementedError();
  }

  Map<String, dynamic> toMap() {
    throw UnimplementedError();
  }
}

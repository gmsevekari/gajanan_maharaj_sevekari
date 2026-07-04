import 'package:cloud_firestore/cloud_firestore.dart';

class VaariParticipant {
  final String memberName;
  final String deviceId;
  final String phone;
  final DateTime joinedAt;
  final int totalSteps;
  final double totalDistance;

  const VaariParticipant({
    required this.memberName,
    required this.deviceId,
    required this.phone,
    required this.joinedAt,
    required this.totalSteps,
    required this.totalDistance,
  });

  factory VaariParticipant.fromMap(Map<String, dynamic> data) {
    return VaariParticipant(
      memberName: data['memberName'] ?? '',
      deviceId: data['deviceId'] ?? '',
      phone: data['phone'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalSteps: data['totalSteps'] ?? 0,
      totalDistance: (data['totalDistance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberName': memberName,
      'deviceId': deviceId,
      'phone': phone,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'totalSteps': totalSteps,
      'totalDistance': totalDistance,
    };
  }
}

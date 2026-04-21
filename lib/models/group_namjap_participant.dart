import 'package:cloud_firestore/cloud_firestore.dart';

class GroupNamjapParticipant {
  final String memberName;     
  final String deviceId;
  final String phone;
  final DateTime joinedAt;
  final int totalCount;
  final Map<String, int> dailyCounts;

  const GroupNamjapParticipant({
    required this.memberName,
    required this.deviceId,
    required this.phone,
    required this.joinedAt,
    required this.totalCount,
    this.dailyCounts = const {},
  });

  factory GroupNamjapParticipant.fromMap(Map<String, dynamic> data) {
    Map<String, int> parsedDailyCounts = {};
    if (data['dailyCounts'] != null) {
      final map = data['dailyCounts'] as Map<String, dynamic>;
      parsedDailyCounts = map.map((key, value) => MapEntry(key, value as int));
    }

    return GroupNamjapParticipant(
      memberName: data['memberName'] ?? '',
      deviceId: data['deviceId'] ?? '',
      phone: data['phone'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      totalCount: data['totalCount'] ?? 0,
      dailyCounts: parsedDailyCounts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberName': memberName,
      'deviceId': deviceId,
      'phone': phone,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'totalCount': totalCount,
      'dailyCounts': dailyCounts,
    };
  }
}

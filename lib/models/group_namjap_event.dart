import 'package:cloud_firestore/cloud_firestore.dart';

class GroupNamjapEvent {
  final String id;
  final String nameEn;
  final String nameMr;
  final String sankalpEn;
  final String sankalpMr;
  final DateTime startDate;
  final DateTime endDate;
  final int targetCount;
  final int totalCount;
  final String joinCode;
  final String status;
  final String groupId;
  final DateTime createdAt;

  const GroupNamjapEvent({
    required this.id,
    required this.nameEn,
    required this.nameMr,
    required this.sankalpEn,
    required this.sankalpMr,
    required this.startDate,
    required this.endDate,
    required this.targetCount,
    required this.totalCount,
    required this.joinCode,
    required this.status,
    required this.groupId,
    required this.createdAt,
  });

  factory GroupNamjapEvent.fromMap(String documentId, Map<String, dynamic> data) {
    return GroupNamjapEvent(
      id: documentId,
      nameEn: data['name_en'] ?? '',
      nameMr: data['name_mr'] ?? '',
      sankalpEn: data['sankalp_en'] ?? '',
      sankalpMr: data['sankalp_mr'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      targetCount: data['targetCount'] ?? 0,
      totalCount: data['totalCount'] ?? 0,
      joinCode: data['joinCode'] ?? '',
      status: data['status'] ?? 'upcoming',
      groupId: data['groupId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name_en': nameEn,
      'name_mr': nameMr,
      'sankalp_en': sankalpEn,
      'sankalp_mr': sankalpMr,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetCount': targetCount,
      'totalCount': totalCount,
      'joinCode': joinCode,
      'status': status,
      'groupId': groupId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

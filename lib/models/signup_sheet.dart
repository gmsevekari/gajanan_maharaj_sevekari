import 'package:cloud_firestore/cloud_firestore.dart';

/// A sign-up sheet: an admin-published set of claimable [SignupSlot]s
/// (stored in its own `slots` subcollection) that devotees claim via
/// entries in a flat `entries` subcollection.
class SignupSheet {
  final String? id;
  final String titleEn;
  final String titleMr;
  final String descriptionEn;
  final String descriptionMr;
  final String groupId;
  final String status; // 'draft' | 'published' | 'closed'
  final bool requiresJoinCode;
  final String? joinCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const SignupSheet({
    this.id,
    required this.titleEn,
    required this.titleMr,
    this.descriptionEn = '',
    this.descriptionMr = '',
    required this.groupId,
    this.status = 'draft',
    this.requiresJoinCode = false,
    this.joinCode,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory SignupSheet.fromMap(String id, Map<String, dynamic> data) {
    return SignupSheet(
      id: id,
      titleEn: data['titleEn'] ?? '',
      titleMr: data['titleMr'] ?? '',
      descriptionEn: data['descriptionEn'] ?? '',
      descriptionMr: data['descriptionMr'] ?? '',
      groupId: data['groupId'] ?? '',
      status: data['status'] ?? 'draft',
      requiresJoinCode: data['requiresJoinCode'] ?? false,
      joinCode: data['joinCode'],
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titleEn': titleEn,
      'titleMr': titleMr,
      'descriptionEn': descriptionEn,
      'descriptionMr': descriptionMr,
      'groupId': groupId,
      'status': status,
      'requiresJoinCode': requiresJoinCode,
      'joinCode': joinCode,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }
}

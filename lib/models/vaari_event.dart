import 'package:cloud_firestore/cloud_firestore.dart';

class VaariEvent {
  final String id;
  final DateTime createdAt;
  final DateTime endDate;
  final String groupId;
  final String joinCode;
  final String nameEn;
  final String nameMr;
  final String descriptionEn;
  final String descriptionMr;
  final DateTime startDate;
  final String status;
  final String timezone;
  final int totalSteps;
  final double totalDistance;
  final double targetDistance;
  final String distanceUnit;

  const VaariEvent({
    required this.id,
    required this.createdAt,
    required this.endDate,
    required this.groupId,
    required this.joinCode,
    required this.nameEn,
    required this.nameMr,
    required this.descriptionEn,
    required this.descriptionMr,
    required this.startDate,
    required this.status,
    required this.timezone,
    required this.totalSteps,
    required this.totalDistance,
    this.targetDistance = 0.0,
    required this.distanceUnit,
  });

  /// Human-readable unit for display — Firestore stores the short code
  /// ('mi'), but the UI should read "miles" rather than the abbreviation.
  String get distanceUnitLabel => distanceUnit == 'mi' ? 'miles' : distanceUnit;

  factory VaariEvent.fromMap(String documentId, Map<String, dynamic> data) {
    return VaariEvent(
      id: documentId,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      groupId: data['groupId'] ?? '',
      joinCode: data['joinCode'] ?? '',
      nameEn: data['nameEn'] ?? data['name_en'] ?? '',
      nameMr: data['nameMr'] ?? data['name_mr'] ?? '',
      descriptionEn: data['descriptionEn'] ?? data['description_en'] ?? '',
      descriptionMr: data['descriptionMr'] ?? data['description_mr'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'upcoming',
      timezone: data['timezone'] ?? 'America/Los_Angeles',
      totalSteps: data['totalSteps'] ?? 0,
      totalDistance: (data['totalDistance'] as num?)?.toDouble() ?? 0.0,
      targetDistance: (data['targetDistance'] as num?)?.toDouble() ?? 0.0,
      distanceUnit: data['distanceUnit'] ?? 'km',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'endDate': Timestamp.fromDate(endDate),
      'groupId': groupId,
      'joinCode': joinCode,
      'nameEn': nameEn,
      'nameMr': nameMr,
      'descriptionEn': descriptionEn,
      'descriptionMr': descriptionMr,
      'startDate': Timestamp.fromDate(startDate),
      'status': status,
      'timezone': timezone,
      'totalSteps': totalSteps,
      'totalDistance': totalDistance,
      'targetDistance': targetDistance,
      'distanceUnit': distanceUnit,
    };
  }

  VaariEvent copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? endDate,
    String? groupId,
    String? joinCode,
    String? nameEn,
    String? nameMr,
    String? descriptionEn,
    String? descriptionMr,
    DateTime? startDate,
    String? status,
    String? timezone,
    int? totalSteps,
    double? totalDistance,
    double? targetDistance,
    String? distanceUnit,
  }) {
    return VaariEvent(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      endDate: endDate ?? this.endDate,
      groupId: groupId ?? this.groupId,
      joinCode: joinCode ?? this.joinCode,
      nameEn: nameEn ?? this.nameEn,
      nameMr: nameMr ?? this.nameMr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionMr: descriptionMr ?? this.descriptionMr,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      timezone: timezone ?? this.timezone,
      totalSteps: totalSteps ?? this.totalSteps,
      totalDistance: totalDistance ?? this.totalDistance,
      targetDistance: targetDistance ?? this.targetDistance,
      distanceUnit: distanceUnit ?? this.distanceUnit,
    );
  }
}

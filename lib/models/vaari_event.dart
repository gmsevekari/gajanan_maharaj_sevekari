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
  final String distanceUnit;

  VaariEvent({
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
    required this.distanceUnit,
  });

  factory VaariEvent.fromMap(String documentId, Map<String, dynamic> data) {
    throw UnimplementedError();
  }

  Map<String, dynamic> toMap() {
    throw UnimplementedError();
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
    String? distanceUnit,
  }) {
    throw UnimplementedError();
  }
}

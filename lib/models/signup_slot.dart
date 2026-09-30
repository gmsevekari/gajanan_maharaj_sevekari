import 'package:cloud_firestore/cloud_firestore.dart';

/// A single claimable slot within a [SignupSheet]'s `slots` subcollection.
class SignupSlot {
  final String? id;
  final String labelEn;
  final String labelMr;
  final DateTime? date;
  final int capacity;
  final int claimedCount;
  final double? suggestedAmount;
  final int sortOrder;
  final DateTime createdAt;

  const SignupSlot({
    this.id,
    required this.labelEn,
    required this.labelMr,
    this.date,
    required this.capacity,
    this.claimedCount = 0,
    this.suggestedAmount,
    required this.sortOrder,
    required this.createdAt,
  });

  factory SignupSlot.fromMap(String id, Map<String, dynamic> data) {
    return SignupSlot(
      id: id,
      labelEn: data['labelEn'] ?? '',
      labelMr: data['labelMr'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate(),
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      claimedCount: (data['claimedCount'] as num?)?.toInt() ?? 0,
      suggestedAmount: (data['suggestedAmount'] as num?)?.toDouble(),
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'labelEn': labelEn,
      'labelMr': labelMr,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'capacity': capacity,
      'claimedCount': claimedCount,
      'suggestedAmount': suggestedAmount,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

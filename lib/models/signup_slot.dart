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
      labelEn: data['labelEn'] is String ? data['labelEn'] as String : '',
      labelMr: data['labelMr'] is String ? data['labelMr'] as String : '',
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : null,
      capacity: data['capacity'] is num ? (data['capacity'] as num).toInt() : 0,
      claimedCount: data['claimedCount'] is num
          ? (data['claimedCount'] as num).toInt()
          : 0,
      suggestedAmount: data['suggestedAmount'] is num
          ? (data['suggestedAmount'] as num).toDouble()
          : null,
      sortOrder: data['sortOrder'] is num
          ? (data['sortOrder'] as num).toInt()
          : 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
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

  SignupSlot copyWith({
    String? id,
    String? labelEn,
    String? labelMr,
    DateTime? date,
    int? capacity,
    int? claimedCount,
    double? suggestedAmount,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return SignupSlot(
      id: id ?? this.id,
      labelEn: labelEn ?? this.labelEn,
      labelMr: labelMr ?? this.labelMr,
      date: date ?? this.date,
      capacity: capacity ?? this.capacity,
      claimedCount: claimedCount ?? this.claimedCount,
      suggestedAmount: suggestedAmount ?? this.suggestedAmount,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignupSlot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          labelEn == other.labelEn &&
          labelMr == other.labelMr &&
          date == other.date &&
          capacity == other.capacity &&
          claimedCount == other.claimedCount &&
          suggestedAmount == other.suggestedAmount &&
          sortOrder == other.sortOrder &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      labelEn.hashCode ^
      labelMr.hashCode ^
      date.hashCode ^
      capacity.hashCode ^
      claimedCount.hashCode ^
      suggestedAmount.hashCode ^
      sortOrder.hashCode ^
      createdAt.hashCode;
}

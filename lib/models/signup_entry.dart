import 'package:cloud_firestore/cloud_firestore.dart';

/// A single devotee's claim on a [SignupSlot], stored in a sign-up sheet's
/// flat `entries` subcollection (each entry references its slot via
/// [slotId] rather than living nested under the slot itself).
class SignupEntry {
  final String? id;
  final String slotId;
  final String name;
  final String? phone;
  final String? email;
  final String? deviceId;
  final double? pledgeAmount;
  final String? note;
  final DateTime joinedAt;

  const SignupEntry({
    this.id,
    required this.slotId,
    required this.name,
    this.phone,
    this.email,
    this.deviceId,
    this.pledgeAmount,
    this.note,
    required this.joinedAt,
  });

  factory SignupEntry.fromMap(String id, Map<String, dynamic> data) {
    return SignupEntry(
      id: id,
      slotId: data['slotId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      email: data['email'],
      deviceId: data['deviceId'],
      pledgeAmount: (data['pledgeAmount'] as num?)?.toDouble(),
      note: data['note'],
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slotId': slotId,
      'name': name,
      'phone': phone,
      'email': email,
      'deviceId': deviceId,
      'pledgeAmount': pledgeAmount,
      'note': note,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

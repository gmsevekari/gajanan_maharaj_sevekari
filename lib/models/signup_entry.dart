import 'package:cloud_firestore/cloud_firestore.dart';

/// A devotee's claim on one [SignupSlot], stored in the signup's flat
/// `entries` subcollection.
class SignupEntry {
  /// The longest values the Firestore rules accept (they require `< 100`,
  /// `< 200` and `< 500` characters), so input fields can stop a user before
  /// the write is refused.
  static const int maxNameLength = 99;
  static const int maxEmailLength = 199;
  static const int maxNoteLength = 499;
  static const double maxPledgeAmount = 1000000;

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
      slotId: data['slotId'] is String ? data['slotId'] as String : '',
      name: data['name'] is String ? data['name'] as String : '',
      phone: data['phone'] is String ? data['phone'] as String : null,
      email: data['email'] is String ? data['email'] as String : null,
      deviceId: data['deviceId'] is String ? data['deviceId'] as String : null,
      pledgeAmount: data['pledgeAmount'] is num
          ? (data['pledgeAmount'] as num).toDouble()
          : null,
      note: data['note'] is String ? data['note'] as String : null,
      joinedAt: data['joinedAt'] is Timestamp
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
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

  SignupEntry copyWith({
    String? id,
    String? slotId,
    String? name,
    String? phone,
    String? email,
    String? deviceId,
    double? pledgeAmount,
    String? note,
    DateTime? joinedAt,
  }) {
    return SignupEntry(
      id: id ?? this.id,
      slotId: slotId ?? this.slotId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      deviceId: deviceId ?? this.deviceId,
      pledgeAmount: pledgeAmount ?? this.pledgeAmount,
      note: note ?? this.note,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignupEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          slotId == other.slotId &&
          name == other.name &&
          phone == other.phone &&
          email == other.email &&
          deviceId == other.deviceId &&
          pledgeAmount == other.pledgeAmount &&
          note == other.note &&
          joinedAt == other.joinedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      slotId.hashCode ^
      name.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      deviceId.hashCode ^
      pledgeAmount.hashCode ^
      note.hashCode ^
      joinedAt.hashCode;
}

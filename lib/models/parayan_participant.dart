import 'package:cloud_firestore/cloud_firestore.dart';

class ParayanMember {
  final String name;
  final List<int> assignedAdhyays;
  final Map<String, bool> completions;
  final String? deviceId;
  final String? email;
  final String? phone;

  const ParayanMember({
    required this.name,
    required this.assignedAdhyays,
    required this.completions,
    this.deviceId,
    this.email,
    this.phone,
  });

  factory ParayanMember.fromMap(
    String name,
    Map<String, dynamic> data, {
    String? deviceId,
    String? email,
    String? phone,
  }) {
    final rawCompletions = data['completions'] as Map<dynamic, dynamic>? ?? {};
    final completions = rawCompletions.map((key, value) => MapEntry(key.toString(), value as bool));

    return ParayanMember(
      name: name,
      assignedAdhyays: List<int>.from(data['assignedAdhyays'] ?? []),
      completions: completions,
      deviceId: deviceId,
      email: email,
      phone: phone,
    );
  }

  Map<String, dynamic> toMap() {
    return {'assignedAdhyays': assignedAdhyays, 'completions': completions};
  }
}

class ParayanHousehold {
  final String deviceId;
  final String email;
  final String phone;
  final DateTime joinedAt;
  final Map<String, ParayanMember> members;

  const ParayanHousehold({
    required this.deviceId,
    required this.email,
    required this.phone,
    required this.joinedAt,
    required this.members,
  });

  factory ParayanHousehold.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final membersData = Map<String, dynamic>.from(data['members'] ?? {});
    final deviceId = doc.id;
    final email = data['email'] ?? '';
    final phone = data['phone'] ?? '';

    DateTime joinedAt;
    try {
      joinedAt = (data['joinedAt'] as Timestamp).toDate();
    } catch (_) {
      joinedAt = DateTime.now();
    }

    return ParayanHousehold(
      deviceId: deviceId,
      email: email,
      phone: phone,
      joinedAt: joinedAt,
      members: membersData.map(
        (key, value) => MapEntry(
          key,
          ParayanMember.fromMap(
            key,
            value,
            deviceId: deviceId,
            email: email,
            phone: phone,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phone': phone,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'members': members.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

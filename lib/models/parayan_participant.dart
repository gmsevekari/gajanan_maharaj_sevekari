import 'package:cloud_firestore/cloud_firestore.dart';

class ParayanMember {
  final String name;
  final List<int> assignedAdhyays;
  final Map<String, bool> completions;

  const ParayanMember({
    required this.name,
    required this.assignedAdhyays,
    required this.completions,
  });

  factory ParayanMember.fromMap(String name, Map<String, dynamic> data) {
    return ParayanMember(
      name: name,
      assignedAdhyays: List<int>.from(data['assignedAdhyays'] ?? []),
      completions: Map<String, bool>.from(data['completions'] ?? {}),
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

    return ParayanHousehold(
      deviceId: doc.id,
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      members: membersData.map(
        (key, value) => MapEntry(key, ParayanMember.fromMap(key, value)),
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

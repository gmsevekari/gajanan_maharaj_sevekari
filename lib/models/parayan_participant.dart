import 'package:cloud_firestore/cloud_firestore.dart';

class ParayanMember {
  final String name;
  final List<int> assignedAdhyays;
  final Map<String, bool> completions;
  final DateTime joinedAt;
  final String? deviceId;
  final String? phone;
  final int? globalIndex;
  final int? groupNumber;

  const ParayanMember({
    required this.name,
    required this.assignedAdhyays,
    required this.completions,
    required this.joinedAt,
    this.deviceId,
    this.phone,
    this.globalIndex,
    this.groupNumber,
  });

  factory ParayanMember.fromMap(
    String name,
    Map<String, dynamic> data, {
    String? deviceId,
    String? phone,
  }) {
    final rawCompletions = data['completions'] as Map<dynamic, dynamic>? ?? {};
    final completions = rawCompletions.map(
      (key, value) => MapEntry(key.toString(), value as bool),
    );

    DateTime joinedAt;
    try {
      joinedAt = (data['joinedAt'] as Timestamp).toDate();
    } catch (_) {
      // Default to a fixed past date for legacy data compatibility
      joinedAt = DateTime(2024, 1, 1);
    }

    return ParayanMember(
      name: data['memberName'] ?? data['name'] ?? name,
      assignedAdhyays: List<int>.from(data['assignedAdhyays'] ?? []),
      completions: completions,
      joinedAt: joinedAt,
      deviceId: data['deviceId'] ?? deviceId,
      phone: data['phone'] ?? phone,
      globalIndex: data['globalIndex'] as int?,
      groupNumber: data['groupNumber'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberName': name,
      'name': name, // backward compatibility
      'assignedAdhyays': assignedAdhyays,
      'completions': completions,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'deviceId': deviceId,
      'phone': phone,
      'globalIndex': globalIndex,
      'groupNumber': groupNumber,
    };
  }

  bool get isFullyCompleted =>
      assignedAdhyays.isNotEmpty &&
      completions.isNotEmpty &&
      completions.values.every((v) => v);
}

class ParayanHousehold {
  final String deviceId;
  final String phone;
  final DateTime joinedAt;
  final Map<String, ParayanMember> members;

  const ParayanHousehold({
    required this.deviceId,
    required this.phone,
    required this.joinedAt,
    required this.members,
  });

  factory ParayanHousehold.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final deviceId = data['deviceId'] ?? doc.id;
    final phone = data['phone'] ?? '';

    DateTime joinedAt;
    try {
      joinedAt = (data['joinedAt'] as Timestamp).toDate();
    } catch (_) {
      joinedAt = DateTime.now();
    }

    // Check if this is a flattened member doc or an old household doc
    if (data.containsKey('memberName') || data.containsKey('assignedAdhyays')) {
      // Virtual household for a single member
      final member = ParayanMember.fromMap(
        '',
        data,
        deviceId: deviceId,
        phone: phone,
      );
      return ParayanHousehold(
        deviceId: deviceId,
        phone: phone,
        joinedAt: joinedAt,
        members: {member.name: member},
      );
    }

    // Traditional household with nested members map
    final membersData = Map<String, dynamic>.from(data['members'] ?? {});
    return ParayanHousehold(
      deviceId: deviceId,
      phone: phone,
      joinedAt: joinedAt,
      members: membersData.map(
        (key, value) => MapEntry(
          key,
          ParayanMember.fromMap(key, value, deviceId: deviceId, phone: phone),
        ),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    // We primarily write via ParayanMember.toMap() now,
    // but keep this for any residual household-level writes.
    return {
      'deviceId': deviceId,
      'phone': phone,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'members': members.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

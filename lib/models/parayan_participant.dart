import 'package:cloud_firestore/cloud_firestore.dart';

class ParayanParticipant {
  final String deviceId;
  final String name;
  final String email;
  final String phone;
  final DateTime joinedAt;
  final List<int> assignedAdhyays;
  final Map<String, bool> completions; // e.g., {"1": true, "2": false} for 3-day

  const ParayanParticipant({
    required this.deviceId,
    required this.name,
    required this.email,
    required this.phone,
    required this.joinedAt,
    required this.assignedAdhyays,
    required this.completions,
  });

  factory ParayanParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParayanParticipant(
      deviceId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      assignedAdhyays: List<int>.from(data['assignedAdhyays'] ?? []),
      completions: Map<String, bool>.from(data['completions'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'assignedAdhyays': assignedAdhyays,
      'completions': completions,
    };
  }
}

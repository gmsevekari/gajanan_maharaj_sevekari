import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle state of a [SignupSheet].
enum SignupSheetStatus {
  draft,
  published,
  closed;

  /// Parses a Firestore string value, defaulting to [draft] for a missing,
  /// wrong-typed, or unrecognized value rather than throwing.
  static SignupSheetStatus fromValue(String? value) {
    return SignupSheetStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SignupSheetStatus.draft,
    );
  }
}

/// A sign-up sheet: an admin-published set of claimable [SignupSlot]s
/// (stored in its own `slots` subcollection) that devotees claim via
/// entries in a flat `entries` subcollection.
class SignupSheet {
  final String? id;
  final String titleEn;
  final String titleMr;
  final String descriptionEn;
  final String descriptionMr;
  final String groupId;
  final SignupSheetStatus status;
  final bool requiresJoinCode;
  final String? joinCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  /// Download URL of an optional admin-uploaded header/display image
  /// (Firebase Storage, `signup_sheets/{id}/header`). Null when no image
  /// has been uploaded.
  final String? headerImageUrl;

  const SignupSheet({
    this.id,
    required this.titleEn,
    required this.titleMr,
    this.descriptionEn = '',
    this.descriptionMr = '',
    required this.groupId,
    this.status = SignupSheetStatus.draft,
    this.requiresJoinCode = false,
    this.joinCode,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.headerImageUrl,
  }) : assert(
         requiresJoinCode || joinCode == null,
         'joinCode must be null when requiresJoinCode is false',
       );

  factory SignupSheet.fromMap(String id, Map<String, dynamic> data) {
    return SignupSheet(
      id: id,
      titleEn: data['titleEn'] is String ? data['titleEn'] as String : '',
      titleMr: data['titleMr'] is String ? data['titleMr'] as String : '',
      descriptionEn: data['descriptionEn'] is String
          ? data['descriptionEn'] as String
          : '',
      descriptionMr: data['descriptionMr'] is String
          ? data['descriptionMr'] as String
          : '',
      groupId: data['groupId'] is String ? data['groupId'] as String : '',
      status: SignupSheetStatus.fromValue(
        data['status'] is String ? data['status'] as String : null,
      ),
      requiresJoinCode: data['requiresJoinCode'] is bool
          ? data['requiresJoinCode'] as bool
          : false,
      joinCode: data['joinCode'] is String ? data['joinCode'] as String : null,
      startDate: data['startDate'] is Timestamp
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] is Timestamp
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['createdBy'] is String ? data['createdBy'] as String : '',
      headerImageUrl: data['headerImageUrl'] is String
          ? data['headerImageUrl'] as String
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titleEn': titleEn,
      'titleMr': titleMr,
      'descriptionEn': descriptionEn,
      'descriptionMr': descriptionMr,
      'groupId': groupId,
      'status': status.name,
      'requiresJoinCode': requiresJoinCode,
      'joinCode': joinCode,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'headerImageUrl': headerImageUrl,
    };
  }

  SignupSheet copyWith({
    String? id,
    String? titleEn,
    String? titleMr,
    String? descriptionEn,
    String? descriptionMr,
    String? groupId,
    SignupSheetStatus? status,
    bool? requiresJoinCode,
    String? joinCode,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? headerImageUrl,
  }) {
    final newRequiresJoinCode = requiresJoinCode ?? this.requiresJoinCode;
    return SignupSheet(
      id: id ?? this.id,
      titleEn: titleEn ?? this.titleEn,
      titleMr: titleMr ?? this.titleMr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionMr: descriptionMr ?? this.descriptionMr,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      requiresJoinCode: newRequiresJoinCode,
      joinCode: newRequiresJoinCode ? (joinCode ?? this.joinCode) : null,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      headerImageUrl: headerImageUrl ?? this.headerImageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignupSheet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          titleEn == other.titleEn &&
          titleMr == other.titleMr &&
          descriptionEn == other.descriptionEn &&
          descriptionMr == other.descriptionMr &&
          groupId == other.groupId &&
          status == other.status &&
          requiresJoinCode == other.requiresJoinCode &&
          joinCode == other.joinCode &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          createdBy == other.createdBy &&
          headerImageUrl == other.headerImageUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      titleEn.hashCode ^
      titleMr.hashCode ^
      descriptionEn.hashCode ^
      descriptionMr.hashCode ^
      groupId.hashCode ^
      status.hashCode ^
      requiresJoinCode.hashCode ^
      joinCode.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      createdBy.hashCode ^
      headerImageUrl.hashCode;
}

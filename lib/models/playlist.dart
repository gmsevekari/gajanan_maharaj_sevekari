import 'package:uuid/uuid.dart';

class Playlist {
  final String id;
  final String name_en;
  final String name_mr;
  final bool isDefault;
  final List<String> aartiIds;
  final DateTime createdAt;

  Playlist({
    String? id,
    required this.name_en,
    required this.name_mr,
    this.isDefault = false,
    List<String>? aartiIds,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        aartiIds = aartiIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Playlist copyWith({
    String? name_en,
    String? name_mr,
    List<String>? aartiIds,
  }) {
    return Playlist(
      id: id,
      name_en: name_en ?? this.name_en,
      name_mr: name_mr ?? this.name_mr,
      isDefault: isDefault,
      aartiIds: aartiIds ?? this.aartiIds,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': name_en,
      'name_mr': name_mr,
      'isDefault': isDefault,
      'aartiIds': aartiIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name_en: json['name_en'] as String? ?? json['name'] as String? ?? 'Playlist',
      name_mr: json['name_mr'] as String? ?? json['name'] as String? ?? 'Playlist',
      isDefault: json['isDefault'] as bool? ?? false,
      aartiIds: List<String>.from(json['aartiIds'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

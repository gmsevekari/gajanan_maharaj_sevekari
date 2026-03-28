import 'package:uuid/uuid.dart';

class Playlist {
  final String id;
  final String name;
  final bool isDefault;
  final List<String> aartiIds;
  final DateTime createdAt;

  Playlist({
    String? id,
    required this.name,
    this.isDefault = false,
    List<String>? aartiIds,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        aartiIds = aartiIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Playlist copyWith({
    String? name,
    List<String>? aartiIds,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      isDefault: isDefault,
      aartiIds: aartiIds ?? this.aartiIds,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isDefault': isDefault,
      'aartiIds': aartiIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      aartiIds: List<String>.from(json['aartiIds'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

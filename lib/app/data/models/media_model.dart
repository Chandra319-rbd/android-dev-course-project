import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'media_model.g.dart';

enum MediaType { image, video }

@HiveType(typeId: AppConstants.mediaTypeId)
class MediaModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String entityId;

  @HiveField(2)
  final String mediaUrl;

  @HiveField(3)
  final String mediaType; // 'image' or 'video'

  @HiveField(4)
  final bool isPrimary;

  @HiveField(5)
  final String? uploadedBy;

  @HiveField(6)
  final DateTime createdAt;

  MediaModel({
    required this.id,
    required this.entityId,
    required this.mediaUrl,
    required this.mediaType,
    this.isPrimary = false,
    this.uploadedBy,
    required this.createdAt,
  });

  /// Check if this is an image
  bool get isImage => mediaType == 'image';

  /// Check if this is a video
  bool get isVideo => mediaType == 'video';

  /// Create from JSON (Supabase response)
  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] as String,
      entityId: json['entity_id'] as String,
      mediaUrl: json['media_url'] as String,
      mediaType: json['media_type'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for Supabase (for insert/update)
  Map<String, dynamic> toJson() {
    return {
      'entity_id': entityId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'is_primary': isPrimary,
      'uploaded_by': uploadedBy,
    };
  }

  /// Convert to JSON with ID (for full serialization)
  Map<String, dynamic> toJsonWithId() {
    return {
      'id': id,
      'entity_id': entityId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'is_primary': isPrimary,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with optional new values
  MediaModel copyWith({
    String? id,
    String? entityId,
    String? mediaUrl,
    String? mediaType,
    bool? isPrimary,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return MediaModel(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      isPrimary: isPrimary ?? this.isPrimary,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MediaModel(id: $id, entityId: $entityId, mediaType: $mediaType, isPrimary: $isPrimary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'review_model.g.dart';

@HiveType(typeId: AppConstants.reviewTypeId)
class ReviewModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String entityId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final int rating;

  @HiveField(4)
  final String? comment;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  // Optional: User info (joined from profiles table)
  @HiveField(7)
  final String? userName;

  @HiveField(8)
  final String? userAvatarUrl;

  @HiveField(9)
  final List<String>? mediaUrls;

  ReviewModel({
    required this.id,
    required this.entityId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
    this.mediaUrls,
  });

  /// Create from JSON (Supabase response)
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Handle joined profile data
    final profile = json['profiles'] as Map<String, dynamic>?;

    // Handle joined media data
    final mediaList = json['review_media'] as List<dynamic>?;
    final urls = mediaList?.map((m) => m['media_url'] as String).toList();

    return ReviewModel(
      id: json['id'] as String,
      entityId: json['entity_id'] as String,
      userId: json['user_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: profile?['full_name'] as String?,
      userAvatarUrl: profile?['avatar_url'] as String?,
      mediaUrls: urls,
    );
  }

  /// Convert to JSON for Supabase (for insert/update)
  Map<String, dynamic> toJson() {
    return {
      'entity_id': entityId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
    };
  }

  /// Convert to JSON with ID (for full serialization)
  Map<String, dynamic> toJsonWithId() {
    return {
      'id': id,
      'entity_id': entityId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with optional new values
  ReviewModel copyWith({
    String? id,
    String? entityId,
    String? userId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatarUrl,
    List<String>? mediaUrls,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
    );
  }

  @override
  String toString() {
    return 'ReviewModel(id: $id, entityId: $entityId, userId: $userId, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import 'phone_number_model.dart';
import 'media_model.dart';

part 'entity_model.g.dart';

@HiveType(typeId: AppConstants.entityTypeId)
class EntityModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String? address;

  @HiveField(5)
  final List<PhoneNumberModel> phoneNumbers;

  @HiveField(6)
  final String? openingHours;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  // Optional: Media list (joined from entity_media table)
  @HiveField(9)
  final List<MediaModel>? media;

  // Optional: Average rating (calculated)
  @HiveField(10)
  final double? averageRating;

  // Optional: Review count
  @HiveField(11)
  final int? reviewCount;

  @HiveField(12)
  final double? latitude;

  @HiveField(13)
  final double? longitude;

  EntityModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    this.address,
    this.phoneNumbers = const [],
    this.openingHours,
    required this.createdAt,
    required this.updatedAt,
    this.media,
    this.averageRating,
    this.reviewCount,
    this.latitude,
    this.longitude,
  });

  /// Get primary image URL
  String? get primaryImageUrl {
    if (media == null || media!.isEmpty) return null;
    final primary = media!.where((m) => m.isPrimary && m.isImage).firstOrNull;
    if (primary != null) return primary.mediaUrl;
    final firstImage = media!.where((m) => m.isImage).firstOrNull;
    return firstImage?.mediaUrl;
  }

  /// Get all image URLs
  List<String> get imageUrls {
    if (media == null) return [];
    return media!.where((m) => m.isImage).map((m) => m.mediaUrl).toList();
  }

  /// Get all video URLs
  List<String> get videoUrls {
    if (media == null) return [];
    return media!.where((m) => m.isVideo).map((m) => m.mediaUrl).toList();
  }

  /// Create from JSON (Supabase response)
  factory EntityModel.fromJson(Map<String, dynamic> json) {
    // Parse phone numbers from JSONB
    final phoneNumbersJson = json['phone_numbers'] as List<dynamic>?;
    final phoneNumbers =
        phoneNumbersJson
            ?.map((p) => PhoneNumberModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse media if joined
    final mediaJson = json['entity_media'] as List<dynamic>?;
    final media = mediaJson
        ?.map((m) => MediaModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return EntityModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      phoneNumbers: phoneNumbers,
      openingHours: json['opening_hours'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      media: media,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  /// Convert to JSON for Supabase (for insert/update)
  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
      'description': description,
      'address': address,
      'phone_numbers': phoneNumbers.map((p) => p.toJson()).toList(),
      'opening_hours': openingHours,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Convert to JSON with ID (for full serialization)
  Map<String, dynamic> toJsonWithId() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'address': address,
      'phone_numbers': phoneNumbers.map((p) => p.toJson()).toList(),
      'opening_hours': openingHours,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with optional new values
  EntityModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    String? address,
    List<PhoneNumberModel>? phoneNumbers,
    String? openingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MediaModel>? media,
    double? averageRating,
    int? reviewCount,
    double? latitude,
    double? longitude,
  }) {
    return EntityModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      openingHours: openingHours ?? this.openingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      media: media ?? this.media,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() {
    return 'EntityModel(id: $id, name: $name, categoryId: $categoryId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EntityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

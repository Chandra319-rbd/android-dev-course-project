import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'category_model.g.dart';

@HiveType(typeId: AppConstants.categoryTypeId)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String iconName;

  @HiveField(3)
  final String color;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    this.imageUrl,
    required this.createdAt,
  });

  /// Create from JSON (Supabase response)
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String,
      color: json['color'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for Supabase (for insert/update)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon_name': iconName,
      'color': color,
      'image_url': imageUrl,
    };
  }

  /// Convert to JSON with ID (for full serialization)
  Map<String, dynamic> toJsonWithId() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color': color,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with optional new values
  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconName,
    String? color,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, iconName: $iconName, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

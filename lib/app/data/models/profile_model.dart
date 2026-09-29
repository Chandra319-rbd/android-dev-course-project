import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'profile_model.g.dart';

@HiveType(typeId: AppConstants.profileTypeId)
class ProfileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? email;

  @HiveField(2)
  final String? fullName;

  @HiveField(3)
  final String? avatarUrl;

  @HiveField(4)
  final bool isAdmin;

  @HiveField(5)
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.isAdmin = false,
    required this.createdAt,
  });

  /// Get display name (full name or email or 'User')
  String get displayName => fullName ?? email ?? 'User';

  /// Get initials for avatar fallback
  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final words = fullName!.trim().split(' ');
      if (words.length == 1) {
        return words[0].substring(0, 1).toUpperCase();
      }
      return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return 'U';
  }

  /// Create from JSON (Supabase response)
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for Supabase (for insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'is_admin': isAdmin,
    };
  }

  /// Convert to JSON with all fields (for full serialization)
  Map<String, dynamic> toJsonWithId() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with optional new values
  ProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    bool? isAdmin,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ProfileModel(id: $id, email: $email, fullName: $fullName, isAdmin: $isAdmin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

/// Repository for managing users (admin operations)
class UserRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get all users from the profiles table
  Future<List<ProfileModel>> getAllUsers() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProfileModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Search users by name or email
  Future<List<ProfileModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllUsers();
      }

      final response = await _client
          .from('profiles')
          .select()
          .or('full_name.ilike.%$query%,email.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProfileModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Get user by ID
  Future<ProfileModel?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Update user admin status
  Future<bool> updateUserAdminStatus(String userId, bool isAdmin) async {
    try {
      await _client
          .from('profiles')
          .update({'is_admin': isAdmin})
          .eq('id', userId);

      return true;
    } catch (e) {
      throw Exception('Failed to update user admin status: $e');
    }
  }

  /// Delete user profile
  /// This will delete the profile record from the profiles table
  /// First handles entity_media and review_media references
  Future<bool> deleteUser(String userId) async {
    try {
      print('[UserRepository] Attempting to delete user: $userId');

      // Step 1: Set uploaded_by to NULL for entity_media
      print('[UserRepository] Updating entity_media uploaded_by to NULL');
      await _client
          .from('entity_media')
          .update({'uploaded_by': null})
          .eq('uploaded_by', userId);

      // Step 2: Set uploaded_by to NULL for review_media (if exists)
      print('[UserRepository] Updating review_media uploaded_by to NULL');
      await _client
          .from('review_media')
          .update({'uploaded_by': null})
          .eq('uploaded_by', userId);

      // Step 3: Now delete the user profile (reviews will cascade automatically)
      print('[UserRepository] Deleting user profile');
      final response = await _client.from('profiles').delete().eq('id', userId);

      print('[UserRepository] Delete response: $response');
      print('[UserRepository] User deleted successfully: $userId');

      return true;
    } catch (e) {
      print('[UserRepository] ERROR deleting user $userId: $e');
      print('[UserRepository] Error type: ${e.runtimeType}');
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Get total user count
  Future<int> getUserCount() async {
    try {
      final response = await _client
          .from('profiles')
          .select('id')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      throw Exception('Failed to get user count: $e');
    }
  }

  /// Get admin count
  Future<int> getAdminCount() async {
    try {
      final response = await _client
          .from('profiles')
          .select('id')
          .eq('is_admin', true)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      throw Exception('Failed to get admin count: $e');
    }
  }
}

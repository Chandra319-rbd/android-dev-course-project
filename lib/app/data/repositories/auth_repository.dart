import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

/// Repository for handling authentication operations with Supabase
class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Check if user is anonymous
  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );

    // Create profile after sign up
    if (response.user != null) {
      await _createProfile(response.user!, fullName: fullName);
    }

    return response;
  }

  /// Sign in anonymously (as guest)
  Future<AuthResponse> signInAnonymously() async {
    return await _client.auth.signInAnonymously();
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get current user's profile from database
  Future<ProfileModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return ProfileModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Create profile for new user
  Future<ProfileModel?> _createProfile(User user, {String? fullName}) async {
    try {
      final profile = ProfileModel(
        id: user.id,
        email: user.email,
        fullName: fullName ?? user.userMetadata?['full_name'],
        avatarUrl: user.userMetadata?['avatar_url'],
        isAdmin: false,
        createdAt: DateTime.now(),
      );

      await _client.from('profiles').upsert(profile.toJson());
      return profile;
    } catch (e) {
      print('Error creating profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<ProfileModel?> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final updates = <String, dynamic>{
        'id': user.id,
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      await _client.from('profiles').upsert(updates);
      return getCurrentProfile();
    } catch (e) {
      print('Error updating profile: $e');
      return null;
    }
  }

  /// Check if current user is admin
  Future<bool> checkIsAdmin() async {
    final profile = await getCurrentProfile();
    return profile?.isAdmin ?? false;
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Delete account (only deletes profile, auth user remains)
  Future<void> deleteProfile() async {
    final user = currentUser;
    if (user == null) return;

    await _client.from('profiles').delete().eq('id', user.id);
  }

  /// Convert anonymous user to permanent account
  Future<AuthResponse> linkAnonymousToEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      ),
    );

    // Update profile with email
    if (response.user != null) {
      await _createProfile(response.user!, fullName: fullName);
    }

    return AuthResponse(
      session: _client.auth.currentSession,
      user: response.user,
    );
  }

  /// Upload avatar image to Supabase Storage
  Future<String?> uploadAvatar(File imageFile) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${user.id}/avatar.$fileExt';
      final bytes = await imageFile.readAsBytes();

      // Upload to avatars bucket
      await _client.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _client.storage.from('avatars').getPublicUrl(fileName);

      // Update profile with new avatar URL
      await updateProfile(avatarUrl: publicUrl);

      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  /// Delete current avatar from storage
  Future<bool> deleteAvatar() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      // List files in user's folder
      final files = await _client.storage.from('avatars').list(path: user.id);

      if (files.isNotEmpty) {
        final filePaths = files.map((f) => '${user.id}/${f.name}').toList();
        await _client.storage.from('avatars').remove(filePaths);
      }

      // Update profile to remove avatar URL
      await updateProfile(avatarUrl: '');

      return true;
    } catch (e) {
      print('Error deleting avatar: $e');
      return false;
    }
  }
}

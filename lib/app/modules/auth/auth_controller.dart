import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

/// Global AuthController for managing authentication state
class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  // Observable state
  final Rx<User?> _user = Rx<User?>(null);
  final Rx<ProfileModel?> _profile = Rx<ProfileModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAdmin = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool _isGuestMode = false.obs;

  // Getters
  User? get user => _user.value;
  ProfileModel? get profile => _profile.value;
  bool get isLoggedIn => _user.value != null;
  bool get isGuestMode => _isGuestMode.value;
  bool get isAnonymous =>
      _isGuestMode.value || (_user.value?.isAnonymous ?? true);
  String get displayName =>
      _isGuestMode.value ? 'Guest' : (_profile.value?.displayName ?? 'Guest');
  String get initials =>
      _isGuestMode.value ? 'G' : (_profile.value?.initials ?? 'G');
  String? get avatarUrl =>
      _isGuestMode.value ? null : _profile.value?.avatarUrl;
  String? get email => _isGuestMode.value ? null : _user.value?.email;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    _initAuthListener();
    _checkCurrentUser();
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  /// Initialize auth state listener
  void _initAuthListener() {
    _authSubscription = _authRepository.authStateChanges.listen((state) {
      _handleAuthStateChange(state);
    });
  }

  /// Handle auth state changes
  void _handleAuthStateChange(AuthState state) {
    _user.value = state.session?.user;

    switch (state.event) {
      case AuthChangeEvent.signedIn:
        _isGuestMode.value = false;
        _loadProfile();
        break;
      case AuthChangeEvent.signedOut:
        _clearProfile();
        break;
      case AuthChangeEvent.userUpdated:
        _loadProfile();
        break;
      case AuthChangeEvent.tokenRefreshed:
        // Token refreshed, no action needed
        break;
      default:
        break;
    }
  }

  /// Check current user on app start
  Future<void> _checkCurrentUser() async {
    _user.value = _authRepository.currentUser;
    if (_user.value != null) {
      await _loadProfile();
    }
  }

  /// Load user profile from database
  Future<void> _loadProfile() async {
    if (_user.value == null) return;

    try {
      _profile.value = await _authRepository.getCurrentProfile();
      isAdmin.value = _profile.value?.isAdmin ?? false;
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  /// Clear profile data
  void _clearProfile() {
    _profile.value = null;
    isAdmin.value = false;
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _authRepository.signInWithEmail(email: email, password: password);

      _isGuestMode.value = false;
      await _loadProfile();
      return true;
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      _showErrorSnackbar(e.message);
      return false;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred';
      _showErrorSnackbar('An unexpected error occurred');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        _isGuestMode.value = false;
        await _loadProfile();
        _showSuccessSnackbar('Account created successfully!');
        return true;
      }

      return false;
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      _showErrorSnackbar(e.message);
      return false;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred';
      _showErrorSnackbar('An unexpected error occurred');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign in as guest (no account needed)
  Future<bool> signInAsGuest() async {
    _isGuestMode.value = true;
    _showSuccessSnackbar('Browsing as guest');
    return true;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      isLoading.value = true;

      // If in guest mode, just clear the flag and go to login
      if (_isGuestMode.value) {
        _isGuestMode.value = false;
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      await _authRepository.signOut();
      _clearProfile();
      _showSuccessSnackbar('Signed out successfully');
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      _showErrorSnackbar('Error signing out');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({String? fullName, String? avatarUrl}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final updatedProfile = await _authRepository.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
      );

      if (updatedProfile != null) {
        _profile.value = updatedProfile;
        _showSuccessSnackbar('Profile updated successfully');
        return true;
      }

      return false;
    } catch (e) {
      errorMessage.value = 'Error updating profile';
      _showErrorSnackbar('Error updating profile');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Upload and update avatar
  Future<bool> uploadAvatar(File imageFile) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final avatarUrl = await _authRepository.uploadAvatar(imageFile);

      if (avatarUrl != null) {
        // Reload profile to get updated avatar URL
        await _loadProfile();
        _showSuccessSnackbar('Profile photo updated');
        return true;
      }

      _showErrorSnackbar('Failed to upload photo');
      return false;
    } catch (e) {
      errorMessage.value = 'Error uploading photo';
      _showErrorSnackbar('Error uploading photo');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete avatar
  Future<bool> deleteAvatar() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final success = await _authRepository.deleteAvatar();

      if (success) {
        await _loadProfile();
        _showSuccessSnackbar('Profile photo removed');
        return true;
      }

      return false;
    } catch (e) {
      errorMessage.value = 'Error removing photo';
      _showErrorSnackbar('Error removing photo');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _authRepository.sendPasswordResetEmail(email);
      _showSuccessSnackbar('Password reset email sent');
      return true;
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      _showErrorSnackbar(e.message);
      return false;
    } catch (e) {
      errorMessage.value = 'Error sending reset email';
      _showErrorSnackbar('Error sending reset email');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Convert anonymous account to email account
  Future<bool> linkToEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _authRepository.linkAnonymousToEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      await _loadProfile();
      _showSuccessSnackbar('Account linked successfully!');
      return true;
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      _showErrorSnackbar(e.message);
      return false;
    } catch (e) {
      errorMessage.value = 'Error linking account';
      _showErrorSnackbar('Error linking account');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to login if not authenticated
  void requireAuth({String? redirectTo}) {
    if (!isLoggedIn || isAnonymous) {
      Get.toNamed(AppRoutes.login);
    }
  }

  /// Check if user can perform action (logged in and not anonymous)
  bool canPerformAuthAction() {
    return isLoggedIn && !isAnonymous;
  }

  // Helper methods for snackbars
  void _showErrorSnackbar(String message) {
    if (Get.context != null) {
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (Get.context != null) {
      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        duration: const Duration(seconds: 2),
      );
    }
  }
}

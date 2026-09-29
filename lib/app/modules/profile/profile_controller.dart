import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/auth_controller.dart';
import '../../routes/app_routes.dart';

/// Controller for Profile Page
class ProfileController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final ImagePicker _imagePicker = ImagePicker();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxBool isUploadingPhoto = false.obs;

  /// Navigate to login page (clears navigation stack)
  void navigateToLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  /// Navigate to sign up (with sign up mode, clears navigation stack)
  void navigateToSignUp() {
    Get.offAllNamed(AppRoutes.login, arguments: {'signUp': true});
  }

  /// Navigate to my reviews (placeholder - will be implemented in Phase 4)
  void navigateToMyReviews() {
    Get.snackbar(
      'Coming Soon',
      'My Reviews feature will be available soon!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Navigate to admin dashboard
  void navigateToAdminDashboard() {
    Get.toNamed(AppRoutes.adminDashboard);
  }

  /// Sign out
  Future<void> signOut() async {
    await _authController.signOut();
  }

  /// Update profile
  Future<void> updateProfile({String? fullName}) async {
    if (fullName != null && fullName.isNotEmpty) {
      await _authController.updateProfile(fullName: fullName);
    }
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not access gallery',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Take photo with camera
  Future<void> takePhotoWithCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not access camera',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Upload selected image
  Future<void> _uploadImage(File imageFile) async {
    isUploadingPhoto.value = true;
    try {
      await _authController.uploadAvatar(imageFile);
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  /// Remove current profile photo
  Future<void> removeProfilePhoto() async {
    isUploadingPhoto.value = true;
    try {
      await _authController.deleteAvatar();
    } finally {
      isUploadingPhoto.value = false;
    }
  }
}

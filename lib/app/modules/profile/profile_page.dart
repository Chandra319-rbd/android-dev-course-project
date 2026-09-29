import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/connectivity_indicator.dart';
import '../auth/auth_controller.dart';

/// Profile Screen with user info and settings
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) => Scaffold(
        backgroundColor: AppColors.warmCream,
        appBar: _buildAppBar(),
        body: ConnectivityIndicator(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                children: [
                  // User avatar and info
                  _buildProfileHeader(controller),
                  const SizedBox(height: 24),

                  // Profile options
                  _buildProfileOptions(controller),
                  const SizedBox(height: 24),

                  // Admin section (if admin)
                  _buildAdminSection(controller),

                  // Sign out / Sign in button
                  _buildAuthButton(controller),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Profile'),
      backgroundColor: AppColors.chineseRed,
      foregroundColor: AppColors.pureWhite,
      elevation: 0,
    );
  }

  Widget _buildProfileHeader(ProfileController controller) {
    final authController = Get.find<AuthController>();

    return Obx(
      () => Container(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar with edit button
            _buildAvatarWithEdit(authController, controller),
            const SizedBox(height: 16),

            // Display name
            Text(
              authController.displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 4),

            // Email or Guest label
            Text(
              authController.isAnonymous
                  ? 'Guest User'
                  : authController.email ?? 'No email',
              style: const TextStyle(fontSize: 14, color: AppColors.mediumGray),
            ),

            // Anonymous user prompt to sign up
            if (authController.isAnonymous) ...[
              const SizedBox(height: 16),
              _buildUpgradePrompt(controller),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithEdit(
    AuthController authController,
    ProfileController controller,
  ) {
    return Stack(
      children: [
        // Avatar
        GestureDetector(
          onTap: authController.isAnonymous
              ? null
              : () => _showPhotoOptions(controller, authController),
          child: Obx(
            () => Stack(
              children: [
                _buildAvatar(authController),
                // Loading overlay
                if (controller.isUploadingPhoto.value)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.pureWhite,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Edit badge (only for logged-in users)
        if (!authController.isAnonymous)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showPhotoOptions(controller, authController),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.chineseRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pureWhite, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.pureWhite,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showPhotoOptions(
    ProfileController controller,
    AuthController authController,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppConstants.radiusLg),
            topRight: Radius.circular(AppConstants.radiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 24),
            // Camera option
            _buildPhotoOption(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              onTap: () {
                Get.back();
                controller.takePhotoWithCamera();
              },
            ),
            const SizedBox(height: 12),
            // Gallery option
            _buildPhotoOption(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              onTap: () {
                Get.back();
                controller.pickImageFromGallery();
              },
            ),
            // Remove photo option (only if there's an avatar)
            if (authController.avatarUrl != null &&
                authController.avatarUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPhotoOption(
                icon: Icons.delete_rounded,
                title: 'Remove Photo',
                isDestructive: true,
                onTap: () {
                  Get.back();
                  _confirmRemovePhoto(controller);
                },
              ),
            ],
            const SizedBox(height: 16),
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.mediumGray),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm + 4,
        ),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withOpacity(0.1)
              : AppColors.chineseRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.chineseRed,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? AppColors.error : AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemovePhoto(ProfileController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text(
          'Are you sure you want to remove your profile photo?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.removeProfilePhoto();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AuthController authController) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.chineseRed.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: authController.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                authController.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildAvatarFallback(authController.initials),
              ),
            )
          : _buildAvatarFallback(authController.initials),
    );
  }

  Widget _buildAvatarFallback(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.pureWhite,
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt(ProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.imperialGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.imperialGold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: AppColors.imperialGold, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Create an account to write reviews and save your progress!',
                  style: TextStyle(fontSize: 13, color: AppColors.darkGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.navigateToSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.imperialGold,
                foregroundColor: AppColors.darkGray,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions(ProfileController controller) {
    final authController = Get.find<AuthController>();

    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Edit Profile (only for logged-in users)
            if (!authController.isAnonymous)
              _buildOptionItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () => _showEditProfileDialog(controller),
              ),

            // About
            _buildOptionItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () => _showAboutDialog(),
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.chineseRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Icon(icon, color: AppColors.chineseRed, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.darkGray,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.mediumGray,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(height: 1, indent: 70, color: AppColors.lightGray),
      ],
    );
  }

  Widget _buildAdminSection(ProfileController controller) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      if (!authController.isAdmin.value) return const SizedBox.shrink();

      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(color: AppColors.chineseRed.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                    vertical: AppConstants.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.chineseRed.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.radiusLg),
                      topRight: Radius.circular(AppConstants.radiusLg),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: AppColors.chineseRed,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.chineseRed,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildOptionItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Admin Dashboard',
                  onTap: controller.navigateToAdminDashboard,
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _buildAuthButton(ProfileController controller) {
    final authController = Get.find<AuthController>();

    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: authController.isLoggedIn
            ? OutlinedButton.icon(
                onPressed: controller.signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  ),
                ),
              )
            : ElevatedButton.icon(
                onPressed: controller.navigateToLogin,
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chineseRed,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  ),
                ),
              ),
      ),
    );
  }

  void _showEditProfileDialog(ProfileController controller) {
    final authController = Get.find<AuthController>();
    final nameController = TextEditingController(
      text: authController.profile?.fullName ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.updateProfile(fullName: nameController.text.trim());
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chineseRed,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.chineseRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance,
                color: AppColors.imperialGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '村庄探索',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.chineseRed,
                  ),
                ),
                Text(
                  'Village Explorer',
                  style: TextStyle(fontSize: 12, color: AppColors.mediumGray),
                ),
              ],
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${AppConstants.appVersion}',
              style: TextStyle(color: AppColors.mediumGray),
            ),
            SizedBox(height: 16),
            Text(
              'A beautiful Chinese-style village discovery app for exploring local places, restaurants, and attractions.',
              style: TextStyle(color: AppColors.darkGray),
            ),
            SizedBox(height: 16),
            Text(
              'Android Development Course\nFinal Project',
              style: TextStyle(color: AppColors.mediumGray, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }
}

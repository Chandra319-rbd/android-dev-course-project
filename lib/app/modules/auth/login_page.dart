import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Login Screen with Chinese-style design
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginController>(
      builder: (controller) => Scaffold(
        backgroundColor: AppColors.warmCream,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo/Brand section
                _buildHeader(),
                const SizedBox(height: 40),

                // Form section
                Obx(
                  () => controller.isSignUp.value
                      ? _buildSignUpForm(controller)
                      : _buildSignInForm(controller),
                ),

                const SizedBox(height: 24),

                // Toggle Sign In / Sign Up
                _buildToggleButton(controller),

                const SizedBox(height: 32),

                // Divider
                _buildDivider(),

                const SizedBox(height: 24),

                // Guest sign in
                _buildGuestButton(controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Chinese lantern icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.chineseRed,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: AppColors.chineseRed.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance,
            size: 40,
            color: AppColors.imperialGold,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '村庄探索',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.chineseRed,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Village Explorer',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.mediumGray,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInForm(LoginController controller) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Email field
          _buildTextField(
            controller: controller.emailController,
            label: 'Email',
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: controller.validateEmail,
          ),
          const SizedBox(height: 16),

          // Password field
          Obx(
            () => _buildTextField(
              controller: controller.passwordController,
              label: 'Password',
              hint: 'Enter your password',
              icon: Icons.lock_outline,
              obscureText: !controller.showPassword.value,
              validator: controller.validatePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.showPassword.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.mediumGray,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(controller),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.chineseRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sign In button
          Obx(
            () => _buildPrimaryButton(
              text: 'Sign In',
              isLoading: controller.isLoading.value,
              onPressed: controller.signIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(LoginController controller) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Full Name field
          _buildTextField(
            controller: controller.fullNameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
            validator: controller.validateFullName,
          ),
          const SizedBox(height: 16),

          // Email field
          _buildTextField(
            controller: controller.emailController,
            label: 'Email',
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: controller.validateEmail,
          ),
          const SizedBox(height: 16),

          // Password field
          Obx(
            () => _buildTextField(
              controller: controller.passwordController,
              label: 'Password',
              hint: 'Create a password',
              icon: Icons.lock_outline,
              obscureText: !controller.showPassword.value,
              validator: controller.validatePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.showPassword.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.mediumGray,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Password field
          Obx(
            () => _buildTextField(
              controller: controller.confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Confirm your password',
              icon: Icons.lock_outline,
              obscureText: !controller.showPassword.value,
              validator: controller.validateConfirmPassword,
            ),
          ),
          const SizedBox(height: 24),

          // Sign Up button
          Obx(
            () => _buildPrimaryButton(
              text: 'Create Account',
              isLoading: controller.isLoading.value,
              onPressed: controller.signUp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.darkGray),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.chineseRed),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.pureWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          borderSide: const BorderSide(color: AppColors.chineseRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.mediumGray),
        hintStyle: const TextStyle(color: AppColors.lightGray),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.chineseRed,
        foregroundColor: AppColors.pureWhite,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        elevation: 4,
        shadowColor: AppColors.chineseRed.withOpacity(0.4),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.pureWhite),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
    );
  }

  Widget _buildToggleButton(LoginController controller) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            controller.isSignUp.value
                ? 'Already have an account?'
                : "Don't have an account?",
            style: const TextStyle(color: AppColors.mediumGray),
          ),
          TextButton(
            onPressed: controller.toggleSignUp,
            child: Text(
              controller.isSignUp.value ? 'Sign In' : 'Sign Up',
              style: const TextStyle(
                color: AppColors.chineseRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.lightGray)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.mediumGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.lightGray)),
      ],
    );
  }

  Widget _buildGuestButton(LoginController controller) {
    return Obx(
      () => OutlinedButton.icon(
        onPressed: controller.isLoading.value ? null : controller.signInAsGuest,
        icon: const Icon(Icons.person_outline),
        label: const Text('Continue as Guest'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkGray,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
          side: const BorderSide(color: AppColors.lightGray, width: 2),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(LoginController controller) {
    final emailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(color: AppColors.mediumGray),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
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
              if (emailController.text.isNotEmpty) {
                controller.sendPasswordReset(emailController.text.trim());
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chineseRed,
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }
}

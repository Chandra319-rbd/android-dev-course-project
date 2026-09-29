import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../routes/app_routes.dart';

/// Controller for Login Page
class LoginController extends GetxController {
  // Get the global auth controller
  final AuthController _authController = Get.find<AuthController>();

  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController fullNameController = TextEditingController();

  // Observable state
  final RxBool isSignUp = false.obs;
  final RxBool showPassword = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    super.onClose();
  }

  /// Toggle between sign in and sign up mode
  void toggleSignUp() {
    isSignUp.value = !isSignUp.value;
    _clearForm();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  /// Clear form fields
  void _clearForm() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    fullNameController.clear();
  }

  /// Validate email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate confirm password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate full name
  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Sign in with email
  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    final success = await _authController.signInWithEmail(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    isLoading.value = false;

    if (success) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Sign up with email
  Future<void> signUp() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    final success = await _authController.signUpWithEmail(
      email: emailController.text.trim(),
      password: passwordController.text,
      fullName: fullNameController.text.trim(),
    );

    isLoading.value = false;

    if (success) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Sign in as guest
  Future<void> signInAsGuest() async {
    isLoading.value = true;

    final success = await _authController.signInAsGuest();

    isLoading.value = false;

    if (success) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await _authController.sendPasswordResetEmail(email);
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../modules/auth/auth_controller.dart';

/// Controller for User Management (Admin)
class UserManagementController extends GetxController {
  final UserRepository _userRepository = UserRepository();
  final AuthController _authController = Get.find<AuthController>();

  // Observable states
  final RxList<ProfileModel> users = <ProfileModel>[].obs;
  final RxList<ProfileModel> filteredUsers = <ProfileModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Search
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // Stats
  final RxInt totalUsers = 0.obs;
  final RxInt adminCount = 0.obs;

  // Sort options
  final RxString sortBy = 'created_at'.obs;
  final RxBool sortAscending = false.obs;

  // Current user profile getter
  ProfileModel? get currentUserProfile => _authController.profile;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();

    // Listen to search query changes
    debounce(
      searchQuery,
      (_) => _filterUsers(),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Load all users
  Future<void> _loadUsers() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final fetchedUsers = await _userRepository.getAllUsers();
      users.assignAll(fetchedUsers);
      filteredUsers.assignAll(fetchedUsers);
      _sortUsers();

      // Update stats
      totalUsers.value = users.length;
      adminCount.value = users.where((user) => user.isAdmin).length;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load users. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh users
  Future<void> refreshUsers() async {
    isRefreshing.value = true;
    hasError.value = false;

    try {
      final fetchedUsers = await _userRepository.getAllUsers();
      users.assignAll(fetchedUsers);
      _filterUsers();

      // Update stats
      totalUsers.value = users.length;
      adminCount.value = users.where((user) => user.isAdmin).length;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refresh. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Filter users based on search query
  void _filterUsers() {
    if (searchQuery.value.isEmpty) {
      filteredUsers.assignAll(users);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredUsers.assignAll(
        users.where((user) {
          final name = user.fullName?.toLowerCase() ?? '';
          final email = user.email?.toLowerCase() ?? '';
          return name.contains(query) || email.contains(query);
        }),
      );
    }
    _sortUsers();
  }

  /// Sort users
  void _sortUsers() {
    final sorted = List<ProfileModel>.from(filteredUsers);
    switch (sortBy.value) {
      case 'name':
        sorted.sort(
          (a, b) => sortAscending.value
              ? (a.fullName ?? '').compareTo(b.fullName ?? '')
              : (b.fullName ?? '').compareTo(a.fullName ?? ''),
        );
        break;
      case 'email':
        sorted.sort(
          (a, b) => sortAscending.value
              ? (a.email ?? '').compareTo(b.email ?? '')
              : (b.email ?? '').compareTo(a.email ?? ''),
        );
        break;
      case 'created_at':
        sorted.sort(
          (a, b) => sortAscending.value
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt),
        );
        break;
    }
    filteredUsers.assignAll(sorted);
  }

  /// Change sort option
  void changeSortBy(String value) {
    if (sortBy.value == value) {
      sortAscending.value = !sortAscending.value;
    } else {
      sortBy.value = value;
      sortAscending.value = true;
    }
    _sortUsers();
  }

  /// Toggle admin status for user
  Future<void> toggleAdminStatus(ProfileModel user) async {
    // Prevent self-modification
    if (user.id == _authController.profile?.id) {
      Get.snackbar(
        'Error',
        'You cannot modify your own admin status.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
      return;
    }

    final newStatus = !user.isAdmin;
    final action = newStatus ? 'promote to admin' : 'remove admin access';

    // Confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(newStatus ? 'Promote to Admin' : 'Remove Admin Access'),
        content: Text(
          'Are you sure you want to $action for ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Optimistic update
      final index = users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        final updatedUser = ProfileModel(
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          avatarUrl: user.avatarUrl,
          isAdmin: newStatus,
          createdAt: user.createdAt,
        );
        users[index] = updatedUser;
        _filterUsers();
        adminCount.value = users.where((u) => u.isAdmin).length;
      }

      // Update on server
      await _userRepository.updateUserAdminStatus(user.id, newStatus);

      Get.snackbar(
        'Success',
        '${user.displayName} has been ${newStatus ? 'promoted to admin' : 'removed from admin'}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
      );
    } catch (e) {
      // Rollback on error
      await refreshUsers();
      Get.snackbar(
        'Error',
        'Failed to update admin status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  /// Delete user
  Future<void> deleteUser(ProfileModel user) async {
    // Prevent self-deletion
    if (user.id == _authController.profile?.id) {
      Get.snackbar(
        'Error',
        'You cannot delete your own account from here.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.displayName}?\n\n'
          'This will permanently delete:\n'
          '• User profile\n'
          '• All reviews by this user\n'
          '• All media uploaded by this user\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      print('[UserManagement] User cancelled deletion');
      return;
    }

    print(
      '[UserManagement] Starting delete for user: ${user.id} (${user.displayName})',
    );
    print('[UserManagement] User is admin: ${user.isAdmin}');
    print('[UserManagement] Current user: ${_authController.profile?.id}');

    try {
      // Optimistic delete
      print('[UserManagement] Performing optimistic delete from UI');
      users.removeWhere((u) => u.id == user.id);
      _filterUsers();
      totalUsers.value = users.length;
      adminCount.value = users.where((u) => u.isAdmin).length;

      // Delete from server
      print('[UserManagement] Calling repository deleteUser');
      final result = await _userRepository.deleteUser(user.id);
      print('[UserManagement] Delete result: $result');

      Get.snackbar(
        'Success',
        '${user.displayName} has been deleted.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
      );
      print('[UserManagement] Delete completed successfully');
    } catch (e) {
      // Rollback on error
      print('[UserManagement] ERROR during delete: $e');
      print('[UserManagement] Error type: ${e.runtimeType}');
      print('[UserManagement] Stack trace: ${StackTrace.current}');

      print('[UserManagement] Rolling back - refreshing user list');
      await refreshUsers();

      Get.snackbar(
        'Error',
        'Failed to delete user: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// Retry loading
  Future<void> retryLoading() async {
    await _loadUsers();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}

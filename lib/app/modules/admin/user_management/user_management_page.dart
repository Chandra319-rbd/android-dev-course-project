import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'user_management_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/profile_model.dart';

/// User Management Page (Admin)
class UserManagementPage extends GetView<UserManagementController> {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.chineseRed),
          );
        }

        if (controller.hasError.value) {
          return _buildErrorState();
        }

        return Column(
          children: [
            _buildSearchBar(),
            _buildStatsBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refreshUsers,
                color: AppColors.chineseRed,
                child: controller.filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildUserList(),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Manage Users',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: AppColors.chineseRed,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          onSelected: controller.changeSortBy,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
            const PopupMenuItem(value: 'email', child: Text('Sort by Email')),
            const PopupMenuItem(
              value: 'created_at',
              child: Text('Sort by Date'),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshUsers,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          prefixIcon: const Icon(Icons.search, color: AppColors.mediumGray),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.clear, color: AppColors.mediumGray),
              onPressed: () {
                controller.searchController.clear();
                controller.updateSearchQuery('');
              },
            );
          }),
          filled: true,
          fillColor: AppColors.warmCream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// Build stats bar
  Widget _buildStatsBar() {
    return Obx(
      () => Container(
        color: AppColors.chineseRed.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.people,
              label: 'Total Users',
              value: controller.totalUsers.value.toString(),
              color: AppColors.chineseRed,
            ),
            _buildStatItem(
              icon: Icons.admin_panel_settings,
              label: 'Admins',
              value: controller.adminCount.value.toString(),
              color: AppColors.jadeGreen,
            ),
            _buildStatItem(
              icon: Icons.search,
              label: 'Filtered',
              value: controller.filteredUsers.length.toString(),
              color: AppColors.indigoBlue,
            ),
          ],
        ),
      ),
    );
  }

  /// Build stat item
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.mediumGray),
            ),
          ],
        ),
      ],
    );
  }

  /// Build user list
  Widget _buildUserList() {
    return Obx(
      () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.filteredUsers.length,
        itemBuilder: (context, index) {
          final user = controller.filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  /// Build user card
  Widget _buildUserCard(ProfileModel user) {
    final isCurrentUser = user.id == controller.currentUserProfile?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildAvatar(user),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user.isAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.jadeGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: AppColors.jadeGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.indigoBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(
                    color: AppColors.indigoBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (user.email != null)
              Text(
                user.email!,
                style: const TextStyle(
                  color: AppColors.mediumGray,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Joined ${_formatDate(user.createdAt)}',
              style: const TextStyle(color: AppColors.lightGray, fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.mediumGray),
          onSelected: (value) {
            if (value == 'toggle_admin') {
              controller.toggleAdminStatus(user);
            } else if (value == 'delete') {
              controller.deleteUser(user);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_admin',
              enabled: !isCurrentUser,
              child: Row(
                children: [
                  Icon(
                    user.isAdmin
                        ? Icons.remove_moderator
                        : Icons.admin_panel_settings,
                    color: isCurrentUser
                        ? AppColors.lightGray
                        : (user.isAdmin ? Colors.orange : AppColors.jadeGreen),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.isAdmin ? 'Remove Admin' : 'Make Admin',
                    style: TextStyle(
                      color: isCurrentUser
                          ? AppColors.lightGray
                          : AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              enabled: !isCurrentUser,
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: isCurrentUser ? AppColors.lightGray : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete User',
                    style: TextStyle(
                      color: isCurrentUser ? AppColors.lightGray : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build avatar
  Widget _buildAvatar(ProfileModel user) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.chineseRed.withOpacity(0.1),
      backgroundImage: user.avatarUrl != null
          ? NetworkImage(user.avatarUrl!)
          : null,
      child: user.avatarUrl == null
          ? Text(
              user.initials,
              style: const TextStyle(
                color: AppColors.chineseRed,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.searchQuery.value.isEmpty
                  ? Icons.people_outline
                  : Icons.search_off,
              size: 64,
              color: AppColors.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              controller.searchQuery.value.isEmpty
                  ? 'No users found'
                  : 'No users match your search',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.searchQuery.value.isEmpty
                  ? 'Users will appear here once they sign up'
                  : 'Try a different search term',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mediumGray),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mediumGray),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: controller.retryLoading,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.chineseRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

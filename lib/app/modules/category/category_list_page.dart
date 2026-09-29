import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/cards/entity_card.dart';
import '../../widgets/common/connectivity_indicator.dart';
import '../../widgets/common/shimmer_loading.dart';
import 'category_list_controller.dart';

/// Category List Screen - shows entities in a category
class CategoryListPage extends GetView<CategoryListController> {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: ConnectivityIndicator(
        child: Obx(() {
          // Show loading only when we have no cached data
          if (controller.isLoading.value && controller.entities.isEmpty) {
            return _buildLoadingView();
          }

          // Show error only when we have no cached data
          if (controller.hasError.value && controller.entities.isEmpty) {
            return _buildErrorView();
          }

          // Show content
          return CustomScrollView(
            slivers: [
              // App Bar
              _buildSliverAppBar(),

              // Sort bar
              _buildSortBar(),

              // Entity list or empty state
              controller.entities.isEmpty
                  ? _buildEmptyState()
                  : _buildEntityList(),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        }),
      ),
    );
  }

  /// Build sliver app bar with category info
  Widget _buildSliverAppBar() {
    // Parse category color
    Color categoryColor;
    try {
      String hex = controller.category.color.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      categoryColor = Color(int.parse(hex, radix: 16));
    } catch (e) {
      categoryColor = AppColors.chineseRed;
    }

    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: categoryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.warmCream),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
        title: Text(
          controller.category.name,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.pureWhite,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
                ),
              ),
            ),
            // Decorative pattern
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Entity count badge
            Positioned(
              right: 16,
              bottom: 50,
              child: Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${controller.entities.length} places',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.warmCream),
          onPressed: controller.refreshEntities,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  /// Build sort bar
  Widget _buildSortBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mediumGray.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sort_rounded,
                    size: 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sort by',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.mediumGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSortChip('Name', 'name'),
                    const SizedBox(width: 8),
                    _buildSortChip('Rating', 'rating'),
                    const SizedBox(width: 8),
                    _buildSortChip('New', 'created_at'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    return Obx(() {
      final isSelected = controller.sortBy.value == value;
      return GestureDetector(
        onTap: () => controller.changeSortBy(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.chineseRed : AppColors.pureWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.chineseRed : AppColors.lightGray,
              width: isSelected ? 0 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.chineseRed.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.pureWhite : AppColors.darkGray,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  controller.sortAscending.value
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: AppColors.pureWhite,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  /// Build entity list
  Widget _buildEntityList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: Obx(
        () => SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final entity = controller.entities[index];
            return EntityCard(
              entity: entity,
              onTap: () => controller.goToEntityDetail(entity),
            );
          }, childCount: controller.entities.length),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.mediumGray.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inbox_rounded,
                  size: 64,
                  color: AppColors.mediumGray.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'No Places Found',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.darkGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'There are no places in this category yet.\nCheck back later!',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.mediumGray,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build loading view
  Widget _buildLoadingView() {
    return const SafeArea(child: ShimmerLoading());
  }

  /// Build error view
  Widget _buildErrorView() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.chineseRed.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 64,
                  color: AppColors.chineseRed.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Oops!',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.chineseRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.mediumGray,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: controller.retryLoading,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chineseRed,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.chineseRed.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

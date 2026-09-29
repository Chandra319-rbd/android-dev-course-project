import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/connectivity_indicator.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/star_rating.dart';
import '../../widgets/common/fullscreen_image_viewer.dart';
import '../../widgets/cards/review_card.dart';
import 'entity_detail_controller.dart';

/// Entity Detail Screen - shows full entity information
class EntityDetailPage extends GetView<EntityDetailController> {
  const EntityDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: ConnectivityIndicator(
        child: Obx(() {
          // Show loading only when we have no data at all (not cached)
          if (controller.isLoading.value &&
              controller.entityData.value == null) {
            return const SafeArea(child: ShimmerLoading());
          }

          // Show error only when we have no data at all
          if (controller.hasError.value &&
              controller.entityData.value == null) {
            return _buildErrorView();
          }

          // Show content if we have data (cached or fresh)
          final entity = controller.entityData.value;
          if (entity == null) {
            return const Center(child: Text('Entity not found'));
          }

          return CustomScrollView(
            slivers: [
              // Image/Video carousel
              _buildMediaCarousel(entity.imageUrls),

              // Entity info
              SliverToBoxAdapter(
                child: _buildEntityInfo(entity.name, entity.description),
              ),

              // Contact section
              if (entity.phoneNumbers.isNotEmpty)
                SliverToBoxAdapter(child: _buildContactSection()),

              // Details section
              SliverToBoxAdapter(
                child: _buildDetailsSection(
                  entity.address,
                  entity.openingHours,
                ),
              ),

              // Reviews section
              _buildReviewsSection(),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        }),
      ),
      // Floating action button for reviews
      floatingActionButton: Obx(() {
        if (controller.entityData.value == null) return const SizedBox.shrink();
        return FloatingActionButton(
          onPressed: () => controller.showReviewForm(context),
          backgroundColor: AppColors.chineseRed,
          foregroundColor: AppColors.pureWhite,
          tooltip: controller.userReview.value != null
              ? 'Edit Review'
              : 'Write Review',
          child: Icon(
            controller.userReview.value != null
                ? Icons.edit
                : Icons.rate_review,
          ),
        );
      }),
    );
  }

  /// Build media carousel
  Widget _buildMediaCarousel(List<String> imageUrls) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.chineseRed,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.darkGray,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrls.isEmpty
            ? _buildPlaceholderImage()
            : imageUrls.length == 1
            ? _buildSingleImage(imageUrls.first)
            : _buildCarousel(imageUrls),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.lightGray,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              size: 64,
              color: AppColors.mediumGray,
            ),
            const SizedBox(height: 8),
            Text(
              'No images available',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleImage(String imageUrl) {
    return Builder(
      builder: (context) => _TapToExpandImage(
        imageUrls: [imageUrl],
        initialIndex: 0,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: AppColors.lightGray),
          errorWidget: (context, url, error) => _buildPlaceholderImage(),
        ),
      ),
    );
  }

  Widget _buildCarousel(List<String> imageUrls) {
    return Builder(
      builder: (context) => _TapToExpandImage(
        imageUrls: imageUrls,
        initialIndex: controller.currentMediaIndex.value,
        child: Stack(
          children: [
            CarouselSlider.builder(
              itemCount: imageUrls.length,
              itemBuilder: (context, index, realIndex) {
                return CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) =>
                      Container(color: AppColors.lightGray),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.lightGray,
                    child: const Icon(
                      Icons.broken_image,
                      color: AppColors.mediumGray,
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                height: 300,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                onPageChanged: (index, reason) {
                  controller.changeMediaIndex(index);
                },
              ),
            ),
            // Indicator dots
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    imageUrls.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: controller.currentMediaIndex.value == index
                            ? AppColors.pureWhite
                            : AppColors.pureWhite.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build entity info section
  Widget _buildEntityInfo(String name, String? description) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.displaySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Rating badge
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.imperialGold.withOpacity(0.2),
                        AppColors.imperialGold.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.imperialGold.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: AppColors.imperialGold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.averageRating.toStringAsFixed(1),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.darkGray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' (${controller.reviewCount})',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Description
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              description,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.mediumGray,
                height: 1.7,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build contact section
  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.jadeGreen.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.jadeGreen.withOpacity(0.15),
                      AppColors.jadeGreen.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_rounded,
                  color: AppColors.jadeGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Contact',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Obx(() {
            final entity = controller.entityData.value;
            if (entity == null) return const SizedBox.shrink();

            return Column(
              children: entity.phoneNumbers.map((phone) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (phone.label.isNotEmpty)
                              Text(
                                phone.label,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.mediumGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              phone.number,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => controller.callPhone(phone.number),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.jadeGreen,
                          foregroundColor: AppColors.pureWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  /// Build details section (address, opening hours)
  Widget _buildDetailsSection(String? address, String? openingHours) {
    if (address == null && openingHours == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigoBlue.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.indigoBlue.withOpacity(0.15),
                      AppColors.indigoBlue.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.indigoBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Details',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Address
          if (address != null) ...[
            _buildDetailRow(
              icon: Icons.location_on_rounded,
              iconColor: AppColors.chineseRed,
              label: 'Address',
              value: address,
              onTap: () => controller.openMap(),
            ),
            if (openingHours != null) const SizedBox(height: 18),
          ],

          // Opening hours
          if (openingHours != null)
            _buildDetailRow(
              icon: Icons.access_time_rounded,
              iconColor: AppColors.jadeGreen,
              label: 'Opening Hours',
              value: openingHours,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.mediumGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: onTap != null ? AppColors.chineseRed : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: iconColor.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build reviews section
  Widget _buildReviewsSection() {
    return SliverToBoxAdapter(
      child: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.imperialGold.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.imperialGold.withOpacity(0.2),
                          AppColors.imperialGold.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: AppColors.imperialGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reviews',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Row(
                            children: [
                              StarRating(
                                rating: controller.averageRating,
                                starSize: 16,
                                spacing: 2,
                                allowHalfRating: true,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${controller.averageRating.toStringAsFixed(1)} (${controller.reviewCount})',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.mediumGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Obx(() {
                if (controller.isLoadingReviews.value &&
                    controller.reviews.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: AppColors.chineseRed,
                      ),
                    ),
                  );
                }

                if (controller.reviews.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 48,
                            color: AppColors.mediumGray.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No reviews yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.mediumGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to write a review!',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.mediumGray,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => controller.showReviewForm(context),
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Write a Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.chineseRed,
                              foregroundColor: AppColors.pureWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final currentUserId = controller.currentUser?.id;
                return Column(
                  children: [
                    ...controller.reviews.take(5).map((review) {
                      final isOwnReview =
                          currentUserId != null &&
                          review.userId == currentUserId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ReviewCard(
                          review: review,
                          isOwnReview: isOwnReview,
                          onEdit: isOwnReview
                              ? () => controller.editReview(context, review)
                              : null,
                          onDelete: isOwnReview
                              ? () => controller.deleteReviewConfirm(review)
                              : null,
                        ),
                      );
                    }),
                    if (controller.reviews.length > 5) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to all reviews page
                        },
                        child: Text(
                          'View all ${controller.reviews.length} reviews',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.chineseRed,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Build error view
  Widget _buildErrorView() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 80,
                color: AppColors.mediumGray.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Oops!',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.chineseRed,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: controller.retryLoading,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chineseRed,
                  foregroundColor: AppColors.warmCream,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper widget to detect tap and open fullscreen image viewer
class _TapToExpandImage extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final Widget child;

  const _TapToExpandImage({
    required this.imageUrls,
    required this.initialIndex,
    required this.child,
  });

  void _openFullscreenViewer(BuildContext context) {
    if (imageUrls.isEmpty) return;

    FullscreenImageViewer.show(
      context: context,
      imageUrls: imageUrls,
      initialIndex: initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreenViewer(context),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

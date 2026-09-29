import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/entity_model.dart';
import '../../widgets/common/connectivity_indicator.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/cards/category_card.dart';
import 'home_controller.dart';

/// Home Screen with category grid and featured places
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConnectivityIndicator(
        child: Obx(() {
          Widget content;

          if (controller.isLoading.value && controller.categories.isEmpty) {
            content = const _LoadingView(key: ValueKey('loading'));
          } else if (controller.hasError.value &&
              controller.categories.isEmpty) {
            content = _ErrorView(
              key: const ValueKey('error'),
              message: controller.errorMessage.value,
              onRetry: controller.retryLoading,
            );
          } else {
            content = RefreshIndicator(
              key: const ValueKey('content'),
              onRefresh: controller.refreshData,
              color: AppColors.chineseRed,
              child: CustomScrollView(
                slivers: [
                  // Custom App Bar
                  _buildSliverAppBar(),

                  // Featured Places Section
                  if (controller.featuredEntities.isNotEmpty ||
                      controller.isLoading.value) ...[
                    _buildSectionHeader('Featured Places', '精选地点'),
                    if (controller.featuredEntities.isNotEmpty)
                      _buildFeaturedPlaces()
                    else
                      const SliverToBoxAdapter(child: FeaturedShimmer()),
                  ],

                  // Categories Section
                  _buildSectionHeader('Categories', '分类'),
                  _buildCategoryGrid(),

                  // Bottom padding
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
              ),
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: content,
          );
        }),
      ),
    );
  }

  /// Build custom sliver app bar
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.chineseRed,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warmCream,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.temple_buddhist,
                color: AppColors.chineseRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '村庄探索',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.imperialGold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Village Explorer',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.warmCream,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            // Decorative circles for visual interest
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pureWhite.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -60,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.imperialGold.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildAppBarAction(
          icon: Icons.search_rounded,
          onPressed: controller.goToSearch,
          tooltip: 'Search',
        ),
        _buildAppBarAction(
          icon: Icons.person_outline_rounded,
          onPressed: controller.goToProfile,
          tooltip: 'Profile',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.warmCream, size: 22),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, String chineseTitle) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.chineseRed, AppColors.chineseRedLight],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.chineseRed.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  chineseTitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.mediumGray,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (title == 'Featured Places')
              Container(
                decoration: BoxDecoration(
                  color: AppColors.chineseRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed: () => controller.goToSearch(showAll: true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.chineseRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.chineseRed,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build featured places horizontal scroll
  Widget _buildFeaturedPlaces() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 240,
        child: Obx(
          () => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: controller.featuredEntities.length,
            itemBuilder: (context, index) {
              final entity = controller.featuredEntities[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < controller.featuredEntities.length - 1
                        ? 16
                        : 0,
                  ),
                  child: FeaturedEntityCard(
                    entity: entity,
                    onTap: () => controller.goToEntityDetail(entity),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build category grid (2 columns)
  Widget _buildCategoryGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: Obx(
        () => SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.15,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final category = controller.categories[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 80)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: CategoryCard(
                category: category,
                onTap: () => controller.goToCategory(category),
              ),
            );
          }, childCount: controller.categories.length),
        ),
      ),
    );
  }
}

/// Loading view with shimmer effect
class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading();
  }
}

/// Error view with retry button
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mediumGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
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
    );
  }
}

/// Featured entity card widget for horizontal scroll
class FeaturedEntityCard extends StatefulWidget {
  final EntityModel entity;
  final VoidCallback onTap;

  const FeaturedEntityCard({
    super.key,
    required this.entity,
    required this.onTap,
  });

  @override
  State<FeaturedEntityCard> createState() => _FeaturedEntityCardState();
}

class _FeaturedEntityCardState extends State<FeaturedEntityCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                widget.entity.primaryImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.entity.primaryImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.lightGray),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.lightGray,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: AppColors.mediumGray,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.lightGray,
                        child: const Icon(
                          Icons.place_rounded,
                          size: 48,
                          color: AppColors.mediumGray,
                        ),
                      ),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.35, 0.6, 1.0],
                    ),
                  ),
                ),

                // Featured badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.imperialGold,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.imperialGold.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.inkBlack,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Featured',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.inkBlack,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entity.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.entity.address != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.pureWhite.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: AppColors.pureWhite,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.entity.address!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warmCream.withOpacity(0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.entity.averageRating != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.pureWhite.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: AppColors.imperialGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.entity.averageRating!.toStringAsFixed(1),
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.entity.reviewCount != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${widget.entity.reviewCount})',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.warmCream.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

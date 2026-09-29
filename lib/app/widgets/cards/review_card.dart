import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/review_model.dart';
import '../common/fullscreen_image_viewer.dart';
import '../common/star_rating.dart';

/// A card widget to display a single review
class ReviewCard extends StatelessWidget {
  /// The review to display
  final ReviewModel review;

  /// Whether this review belongs to the current user
  final bool isOwnReview;

  /// Callback when edit button is pressed
  final VoidCallback? onEdit;

  /// Callback when delete button is pressed
  final VoidCallback? onDelete;

  /// Whether to show the entity name (useful in profile view)
  final String? entityName;

  const ReviewCard({
    super.key,
    required this.review,
    this.isOwnReview = false,
    this.onEdit,
    this.onDelete,
    this.entityName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isOwnReview
            ? AppColors.chineseRed.withOpacity(0.04)
            : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: isOwnReview
            ? Border.all(
                color: AppColors.chineseRed.withOpacity(0.15),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with user info and rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(width: 14),

              // User name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.userName ?? 'Anonymous',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwnReview)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.chineseRed.withOpacity(0.15),
                                  AppColors.chineseRed.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Your Review',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.chineseRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.mediumGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(review.createdAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                    if (entityName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.chineseRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              size: 12,
                              color: AppColors.chineseRed,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entityName!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.darkGray,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Rating badge
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.imperialGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StarRating(
                      rating: review.rating.toDouble(),
                      starSize: 14,
                      spacing: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Comment
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warmCream.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.comment!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.darkGray,
                  height: 1.6,
                ),
              ),
            ),
          ],

          // Images
          if (review.mediaUrls != null && review.mediaUrls!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.mediaUrls!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => FullscreenImageViewer.show(
                      context: context,
                      imageUrls: review.mediaUrls!,
                      initialIndex: index,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildReviewImage(review.mediaUrls![index]),
                    ),
                  );
                },
              ),
            ),
          ],

          // Action buttons for own review
          if (isOwnReview && (onEdit != null || onDelete != null)) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    color: AppColors.indigoBlue,
                    onPressed: onEdit!,
                  ),
                if (onDelete != null) ...[
                  const SizedBox(width: 10),
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                    color: AppColors.error,
                    onPressed: onDelete!,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewImage(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) =>
            Container(color: Colors.grey[200], child: const Icon(Icons.error)),
      );
    } else {
      return Image.file(
        File(path),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: Colors.grey[200], child: const Icon(Icons.error)),
      );
    }
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.lightGray,
      child: review.userAvatarUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: review.userAvatarUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Icon(Icons.person, color: AppColors.mediumGray),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.person, color: AppColors.mediumGray),
              ),
            )
          : Text(
              _getInitials(review.userName),
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.mediumGray,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays == 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// A list of review cards with optional header
class ReviewsList extends StatelessWidget {
  final List<ReviewModel> reviews;
  final String? currentUserId;
  final void Function(ReviewModel review)? onEditReview;
  final void Function(ReviewModel review)? onDeleteReview;
  final String? Function(String entityId)? getEntityName;
  final bool showEntityName;
  final Widget? emptyWidget;
  final int? maxItems;

  const ReviewsList({
    super.key,
    required this.reviews,
    this.currentUserId,
    this.onEditReview,
    this.onDeleteReview,
    this.getEntityName,
    this.showEntityName = false,
    this.emptyWidget,
    this.maxItems,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return emptyWidget ?? _buildEmptyState();
    }

    final displayReviews = maxItems != null
        ? reviews.take(maxItems!).toList()
        : reviews;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayReviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final review = displayReviews[index];
        final isOwnReview =
            currentUserId != null && review.userId == currentUserId;

        return ReviewCard(
          review: review,
          isOwnReview: isOwnReview,
          onEdit: isOwnReview && onEditReview != null
              ? () => onEditReview!(review)
              : null,
          onDelete: isOwnReview && onDeleteReview != null
              ? () => onDeleteReview!(review)
              : null,
          entityName: showEntityName && getEntityName != null
              ? getEntityName!(review.entityId)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: AppColors.mediumGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your experience!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

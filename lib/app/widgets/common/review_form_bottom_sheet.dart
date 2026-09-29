import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_helper.dart';
import '../../data/models/local/media_item.dart';
import '../../data/models/review_model.dart';
import '../common/star_rating.dart';

/// Bottom sheet widget for creating or editing a review
class ReviewFormBottomSheet extends StatefulWidget {
  /// Entity ID to review
  final String entityId;

  /// Entity name for display
  final String entityName;

  /// Existing review to edit (null for new review)
  final ReviewModel? existingReview;

  /// Callback when review is submitted
  final Future<void> Function(
    int rating,
    String? comment,
    List<File> newImages,
    List<String> keptImageUrls,
  )
  onSubmit;

  /// Callback when review is deleted
  final Future<void> Function()? onDelete;

  const ReviewFormBottomSheet({
    super.key,
    required this.entityId,
    required this.entityName,
    this.existingReview,
    required this.onSubmit,
    this.onDelete,
  });

  /// Show the review form bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String entityId,
    required String entityName,
    ReviewModel? existingReview,
    required Future<void> Function(
      int rating,
      String? comment,
      List<File> newImages,
      List<String> keptImageUrls,
    )
    onSubmit,
    Future<void> Function()? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewFormBottomSheet(
        entityId: entityId,
        entityName: entityName,
        existingReview: existingReview,
        onSubmit: onSubmit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<ReviewFormBottomSheet> createState() => _ReviewFormBottomSheetState();
}

class _ReviewFormBottomSheetState extends State<ReviewFormBottomSheet> {
  late int _rating;
  late TextEditingController _commentController;
  final List<MediaItem> _selectedImages = [];
  bool _isSubmitting = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 0;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );

    if (widget.existingReview?.mediaUrls != null) {
      _selectedImages.addAll(
        widget.existingReview!.mediaUrls!.map(
          (url) => MediaItem(url: url, type: MediaType.image, isExisting: true),
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    final item = await MediaHelper.pickImageFromCamera();
    if (item != null) {
      setState(() {
        _selectedImages.add(item);
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final items = await MediaHelper.pickImagesFromGallery();
    if (items.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(items);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_rating == 0) {
      Get.snackbar(
        'Rating Required',
        'Please select a rating before submitting',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText: AppColors.pureWhite,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final comment = _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim();

      final newImages = _selectedImages
          .where((i) => !i.isExisting && i.file != null)
          .map((i) => i.file!)
          .toList();

      final keptImageUrls = _selectedImages
          .where((i) => i.isExisting && i.url != null)
          .map((i) => i.url!)
          .toList();

      await widget.onSubmit(_rating, comment, newImages, keptImageUrls);
      if (mounted) Navigator.of(context).pop();
      Get.snackbar(
        'Success',
        _isEditing
            ? 'Review updated successfully'
            : 'Review submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: AppColors.pureWhite,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to ${_isEditing ? 'update' : 'submit'} review. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText: AppColors.pureWhite,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleDelete() async {
    if (widget.onDelete == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text(
          'Are you sure you want to delete your review? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      await widget.onDelete!();
      if (mounted) Navigator.of(context).pop();
      Get.snackbar(
        'Success',
        'Review deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: AppColors.pureWhite,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete review. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText: AppColors.pureWhite,
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _isEditing ? 'Edit Your Review' : 'Write a Review',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Entity name
              Text(
                widget.entityName,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Rating section
              Text(
                'Your Rating',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: InteractiveStarRating(
                  initialRating: _rating.toDouble(),
                  starSize: 48,
                  spacing: 12,
                  onRatingChanged: (rating) {
                    setState(() => _rating = rating);
                  },
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getRatingLabel(_rating),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _rating > 0
                        ? AppColors.chineseRed
                        : AppColors.mediumGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Comment section
              Text(
                'Your Review (Optional)',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.lightGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.lightGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.chineseRed),
                  ),
                  filled: true,
                  fillColor: AppColors.lightGray.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 24),

              // Photos section
              Text(
                'Add Photos',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Image list
              if (_selectedImages.isNotEmpty)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final image = _selectedImages[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: image.isExisting
                                ? CachedNetworkImage(
                                    imageUrl: image.url!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.error),
                                        ),
                                  )
                                : Image.file(
                                    image.file!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // Add photo buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting || _isDeleting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chineseRed,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.pureWhite,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Review' : 'Submit Review',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              // Delete button (only for editing)
              if (_isEditing && widget.onDelete != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isSubmitting || _isDeleting
                      ? null
                      : _handleDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_outline, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Delete Review',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }
}

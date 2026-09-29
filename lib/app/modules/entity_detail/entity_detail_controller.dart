import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'entity_map_view.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/optimistic_update_service.dart';
import '../../data/models/entity_model.dart';
import '../../data/models/review_model.dart';
import '../../data/providers/local_storage_provider.dart';
import '../../data/repositories/review_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/review_form_bottom_sheet.dart';
import '../../core/theme/app_colors.dart';

/// Controller for Entity Detail Screen
class EntityDetailController extends GetxController {
  final LocalStorageProvider _localStorage = Get.find<LocalStorageProvider>();
  final ConnectivityService _connectivityService =
      Get.find<ConnectivityService>();
  final OptimisticUpdateService _optimisticService =
      Get.find<OptimisticUpdateService>();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ReviewRepository _reviewRepository = ReviewRepository();

  // Entity data
  late EntityModel entity;
  final RxString entityId = ''.obs;

  // Observable states - will be initialized with cached data if available
  late final Rx<EntityModel?> entityData;
  final RxList<ReviewModel> reviews = <ReviewModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingReviews = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;
  final RxBool isOfflineMode = false.obs;

  // Review states
  final Rx<ReviewModel?> userReview = Rx<ReviewModel?>(null);
  final RxBool isSubmittingReview = false.obs;

  // Media carousel
  final RxInt currentMediaIndex = 0.obs;

  // Auth helpers
  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? true;
  bool get canReview =>
      isLoggedIn && !isAnonymous && _connectivityService.isOnline.value;

  // Constructor - initialize with cached data immediately
  EntityDetailController() {
    // Get entity from arguments or cache
    EntityModel? initialEntity;
    if (Get.arguments is EntityModel) {
      initialEntity = Get.arguments as EntityModel;
      entity = initialEntity;
      entityId.value = initialEntity.id;
    } else {
      final id = Get.parameters['entityId'];
      if (id != null) {
        entityId.value = id;
        initialEntity = _localStorage.getEntityById(id);
        if (initialEntity != null) {
          entity = initialEntity;
        }
      }
    }

    // Initialize entityData with cached value (or null)
    entityData = Rx<EntityModel?>(initialEntity);
  }

  /// Open map with entity location
  Future<void> openMap() async {
    final currentEntity = entityData.value;
    if (currentEntity == null) return;

    double? lat = currentEntity.latitude;
    double? lng = currentEntity.longitude;
    final address = currentEntity.address;

    // If no coordinates but we have address, try to geocode
    if ((lat == null || lng == null) && address != null && address.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }
    }

    if (lat != null && lng != null) {
      Get.to(
        () => EntityMapView(
          latitude: lat!,
          longitude: lng!,
          address: address ?? 'Unknown Location',
          name: currentEntity.name,
        ),
      );
      return;
    }

    // Fallback to external map if we still don't have coordinates
    if (address != null && address.isNotEmpty) {
      final query = Uri.encodeComponent(address);
      final url = 'https://www.google.com/maps/search/?api=1&query=$query';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  void onInit() {
    super.onInit();

    // Start async loading (cached data is already set in constructor)
    _loadEntityDetails();

    // Auto-refresh when back online
    _connectivityService.addOnlineCallback(_onBackOnline);

    // Listen to global entity changes (e.g. rating updates)
    ever(_optimisticService.entities, (_) {
      if (entityId.value.isNotEmpty) {
        final updated = _optimisticService.entities.firstWhereOrNull(
          (e) => e.id == entityId.value,
        );
        if (updated != null) {
          entityData.value = updated;
          entity = updated;
        }
      }
    });
  }

  @override
  void onClose() {
    _connectivityService.removeOnlineCallback(_onBackOnline);
    super.onClose();
  }

  /// Called when device comes back online
  void _onBackOnline() {
    if (entityData.value != null && !isLoading.value) {
      refreshDetails();
    }
  }

  /// Load full entity details
  Future<void> _loadEntityDetails() async {
    if (entityId.value.isEmpty) return;

    // Only show loading if we don't have cached data
    if (entityData.value == null) {
      isLoading.value = true;
    }
    hasError.value = false;
    errorMessage.value = '';
    isOfflineMode.value = !_connectivityService.isOnline.value;

    // If offline, use cached data
    if (!_connectivityService.isOnline.value) {
      final cachedEntity = _localStorage.getEntityById(entityId.value);
      if (cachedEntity != null) {
        entityData.value = cachedEntity;
        entity = cachedEntity;
      }
      isLoading.value = false;
      return;
    }

    try {
      // Fetch entity with media
      final response = await _supabase
          .from('entities')
          .select('''
            *,
            entity_media(*)
          ''')
          .eq('id', entityId.value)
          .single();

      final fetchedEntity = EntityModel.fromJson(response);
      entityData.value = fetchedEntity;
      entity = fetchedEntity;

      // Cache the entity and sync with optimistic service
      await _localStorage.saveEntity(fetchedEntity);
      await _optimisticService.syncEntity(fetchedEntity);

      // Load reviews
      _loadReviews();
    } catch (e) {
      // Try cache on error
      final cachedEntity = _localStorage.getEntityById(entityId.value);
      if (cachedEntity != null) {
        entityData.value = cachedEntity;
        entity = cachedEntity;
        isOfflineMode.value = true;
      } else if (entityData.value == null) {
        hasError.value = true;
        errorMessage.value =
            'Failed to load details. Please check your connection.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Load reviews for entity
  Future<void> _loadReviews() async {
    // First check if we have reviews in optimistic service
    final cachedReviews = _optimisticService.getEntityReviews(entityId.value);
    if (cachedReviews.isNotEmpty) {
      reviews.assignAll(cachedReviews);
    }

    isLoadingReviews.value = true;

    try {
      final fetchedReviews = await _reviewRepository.getReviewsForEntity(
        entityId.value,
      );

      // Update service and local list
      _optimisticService.setEntityReviews(entityId.value, fetchedReviews);
      reviews.assignAll(fetchedReviews);

      // Check if current user has a review
      if (canReview) {
        userReview.value = fetchedReviews.firstWhereOrNull(
          (r) => r.userId == currentUser!.id,
        );
      }
    } catch (e) {
      // Silently fail - reviews are optional
    } finally {
      isLoadingReviews.value = false;
    }
  }

  /// Refresh entity details
  Future<void> refreshDetails() async {
    await _loadEntityDetails();
  }

  /// Retry loading
  Future<void> retryLoading() async {
    await _loadEntityDetails();
  }

  /// Change media index
  void changeMediaIndex(int index) {
    currentMediaIndex.value = index;
  }

  /// Make phone call
  Future<void> callPhone(String phoneNumber) async {
    // Remove all non-numeric characters except +
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Try launching anyway as a fallback, or show error
        // Some devices report false for canLaunchUrl but still work
        try {
          await launchUrl(phoneUri);
        } catch (_) {
          Get.snackbar(
            'Error',
            'Could not make phone call',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not make phone call',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Navigate to login for review
  void goToLoginForReview() {
    Get.toNamed(AppRoutes.login);
  }

  /// Show review form bottom sheet
  void showReviewForm(BuildContext context) {
    if (!canReview) {
      // Show login prompt
      Get.snackbar(
        'Login Required',
        'Please sign in to write a review',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning.withValues(alpha: 0.9),
        colorText: AppColors.pureWhite,
        mainButton: TextButton(
          onPressed: () {
            Get.back();
            Get.toNamed(AppRoutes.login);
          },
          child: const Text(
            'Sign In',
            style: TextStyle(color: AppColors.pureWhite),
          ),
        ),
      );
      return;
    }

    ReviewFormBottomSheet.show(
      context: context,
      entityId: entityId.value,
      entityName: entityData.value?.name ?? 'This place',
      existingReview: userReview.value,
      onSubmit: _submitReview,
      onDelete: userReview.value != null ? _deleteReview : null,
    );
  }

  /// Submit a review (create or update) with optimistic update
  Future<void> _submitReview(
    int rating,
    String? comment,
    List<File> newImages,
    List<String> keptImageUrls,
  ) async {
    isSubmittingReview.value = true;

    try {
      if (userReview.value != null) {
        // Update existing review
        final updatedReview = ReviewModel(
          id: userReview.value!.id,
          entityId: entityId.value,
          userId: currentUser!.id,
          rating: rating,
          comment: comment,
          createdAt: userReview.value!.createdAt,
          updatedAt: DateTime.now(),
          userName: userReview.value!.userName,
          userAvatarUrl: userReview.value!.userAvatarUrl,
          mediaUrls: [...keptImageUrls, ...newImages.map((f) => f.path)],
        );

        // Use optimistic service
        final result = await _optimisticService.updateReview(
          entityId: entityId.value,
          review: updatedReview,
          apiCall: () => _reviewRepository.updateReview(
            reviewId: userReview.value!.id,
            rating: rating,
            comment: comment,
            images: newImages,
            keptImageUrls: keptImageUrls,
          ),
        );

        if (result != null) {
          userReview.value = result;
        }
      } else {
        // Create new review
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final optimisticReview = ReviewModel(
          id: tempId,
          entityId: entityId.value,
          userId: currentUser!.id,
          rating: rating,
          comment: comment,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userName: currentUser?.userMetadata?['full_name'] ?? 'Me',
          userAvatarUrl: currentUser?.userMetadata?['avatar_url'],
          mediaUrls: newImages.map((f) => f.path).toList(),
        );

        // Use optimistic service
        final result = await _optimisticService.addReview(
          entityId: entityId.value,
          review: optimisticReview,
          apiCall: () => _reviewRepository.createReview(
            entityId: entityId.value,
            userId: currentUser!.id,
            rating: rating,
            comment: comment,
            images: newImages,
          ),
        );

        if (result != null) {
          userReview.value = result;
        }
      }

      // Sync local list with service
      reviews.assignAll(_optimisticService.getEntityReviews(entityId.value));
    } catch (e) {
      // Service handles rollback internally, we just need to sync UI
      reviews.assignAll(_optimisticService.getEntityReviews(entityId.value));

      Get.snackbar(
        'Error',
        'Failed to submit review. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmittingReview.value = false;
    }
  }

  /// Delete user's review with optimistic update
  Future<void> _deleteReview() async {
    if (userReview.value == null) return;

    isSubmittingReview.value = true;
    final reviewId = userReview.value!.id;

    try {
      // Use optimistic service
      await _optimisticService.deleteReview(
        entityId: entityId.value,
        reviewId: reviewId,
        apiCall: () => _reviewRepository.deleteReview(reviewId),
      );

      userReview.value = null;

      // Sync local list with service
      reviews.assignAll(_optimisticService.getEntityReviews(entityId.value));
    } catch (e) {
      // Service handles rollback internally
      reviews.assignAll(_optimisticService.getEntityReviews(entityId.value));

      Get.snackbar(
        'Error',
        'Failed to delete review. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmittingReview.value = false;
    }
  }

  /// Edit user's review
  void editReview(BuildContext context, ReviewModel review) {
    if (review.userId != currentUser?.id) return;

    ReviewFormBottomSheet.show(
      context: context,
      entityId: entityId.value,
      entityName: entityData.value?.name ?? 'This place',
      existingReview: review,
      onSubmit: _submitReview,
      onDelete: _deleteReview,
    );
  }

  /// Delete a specific review (for edit/delete buttons on review card)
  Future<void> deleteReviewConfirm(ReviewModel review) async {
    if (review.userId != currentUser?.id) return;

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteReview();
      Get.snackbar(
        'Success',
        'Review deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: AppColors.pureWhite,
      );
    }
  }

  /// Calculate average rating
  double get averageRating {
    if (reviews.isEmpty) return entityData.value?.averageRating ?? 0.0;
    final total = reviews.fold(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  /// Get review count
  int get reviewCount {
    return reviews.isNotEmpty
        ? reviews.length
        : (entityData.value?.reviewCount ?? 0);
  }
}

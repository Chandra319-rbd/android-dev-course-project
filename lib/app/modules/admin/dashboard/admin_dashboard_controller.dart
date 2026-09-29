import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/optimistic_update_service.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/entity_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

/// Controller for Admin Dashboard
class AdminDashboardController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final OptimisticUpdateService _optimisticService =
      Get.find<OptimisticUpdateService>();

  // Stats
  final RxInt categoryCount = 0.obs;
  final RxInt entityCount = 0.obs;
  final RxInt reviewCount = (-1).obs; // -1 indicates loading
  final RxInt userCount = (-1).obs; // -1 indicates loading

  // Bind to optimistic service for instant updates
  RxList<EntityModel> get recentEntities => _optimisticService.entities;
  RxList<CategoryModel> get categories => _optimisticService.categories;

  // Loading states
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialize counts from cached data
    if (_optimisticService.categories.isNotEmpty) {
      categoryCount.value = _optimisticService.categories.length;
    }
    if (_optimisticService.entities.isNotEmpty) {
      entityCount.value = _optimisticService.entities.length;
    }

    _loadDashboardData();

    // Update counts when data changes
    ever(_optimisticService.categories, (_) {
      categoryCount.value = _optimisticService.categories.length;
    });
    ever(_optimisticService.entities, (_) {
      entityCount.value = _optimisticService.entities.length;
    });
  }

  /// Load all dashboard data
  Future<void> _loadDashboardData() async {
    // Check if we have cached data
    final hasCachedData =
        _optimisticService.categories.isNotEmpty ||
        _optimisticService.entities.isNotEmpty;

    // Only show full loading state if we have NO data
    if (!hasCachedData) {
      isLoading.value = true;
    } else {
      isLoading.value = false;
    }

    errorMessage.value = '';

    try {
      // Show cached data immediately
      if (hasCachedData) {
        categoryCount.value = _optimisticService.categories.length;
        entityCount.value = _optimisticService.entities.length;
      }

      // Fetch fresh data from server
      await Future.wait([
        _fetchStats(),
        _fetchRecentEntities(),
        _fetchCategories(),
      ]);
    } catch (e) {
      if (!hasCachedData) {
        errorMessage.value = 'Failed to load dashboard data: $e';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch dashboard statistics
  Future<void> _fetchStats() async {
    try {
      // Get category count
      final categoriesResponse = await _supabase
          .from('categories')
          .select('id')
          .count(CountOption.exact);
      categoryCount.value = categoriesResponse.count;

      // Get entity count
      final entitiesResponse = await _supabase
          .from('entities')
          .select('id')
          .count(CountOption.exact);
      entityCount.value = entitiesResponse.count;

      // Get review count
      final reviewsResponse = await _supabase
          .from('reviews')
          .select('id')
          .count(CountOption.exact);
      reviewCount.value = reviewsResponse.count;

      // Get user count
      final usersResponse = await _supabase
          .from('profiles')
          .select('id')
          .count(CountOption.exact);
      userCount.value = usersResponse.count;
    } catch (e) {
      print('Error fetching stats: $e');
      rethrow;
    }
  }

  /// Fetch recent entities and sync to optimistic service
  Future<void> _fetchRecentEntities() async {
    try {
      final response = await _supabase
          .from('entities')
          .select('''
            *,
            entity_media(*)
          ''')
          .order('created_at', ascending: false);

      final entities = (response as List)
          .map((json) => EntityModel.fromJson(json))
          .toList();

      // Sync to optimistic service
      await _optimisticService.syncEntities(entities);
    } catch (e) {
      print('Error fetching recent entities: $e');
      rethrow;
    }
  }

  /// Fetch all categories and sync to optimistic service
  Future<void> _fetchCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name', ascending: true);

      final fetchedCategories = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      // Sync to optimistic service
      await _optimisticService.syncCategories(fetchedCategories);
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  /// Refresh dashboard data
  Future<void> refreshData() async {
    isRefreshing.value = true;
    try {
      await Future.wait([
        _fetchStats(),
        _fetchRecentEntities(),
        _fetchCategories(),
      ]);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refresh data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Navigate to add new category
  Future<void> goToAddCategory() async {
    final result = await Get.toNamed(AppRoutes.categoryForm);
    if (result == true) {
      await refreshData();
    }
  }

  /// Navigate to edit category
  Future<void> goToEditCategory(CategoryModel category) async {
    final result = await Get.toNamed(
      AppRoutes.categoryForm,
      arguments: category,
    );
    if (result == true) {
      await refreshData();
    }
  }

  /// Navigate to add new entity
  Future<void> goToAddEntity() async {
    final result = await Get.toNamed(AppRoutes.entityForm);
    if (result == true) {
      await refreshData();
    }
  }

  /// Navigate to edit entity
  Future<void> goToEditEntity(EntityModel entity) async {
    final result = await Get.toNamed(AppRoutes.entityForm, arguments: entity);
    if (result == true) {
      await refreshData();
    }
  }

  /// Navigate to entity detail
  void goToEntityDetail(EntityModel entity) {
    Get.toNamed(AppRoutes.entityDetailRoute(entity.id), arguments: entity);
  }

  /// Delete category with confirmation (optimistic update)
  Future<void> deleteCategory(CategoryModel category) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? '
          'This will also delete all entities in this category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Optimistic delete - UI updates instantly
        await _optimisticService.deleteCategory(
          categoryId: category.id,
          apiCall: () async {
            await _supabase.from('categories').delete().eq('id', category.id);
          },
        );
        categoryCount.value--;
        Get.snackbar(
          'Success',
          'Category deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete category: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  /// Delete entity with confirmation (optimistic update)
  Future<void> deleteEntity(EntityModel entity) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Entity'),
        content: Text('Are you sure you want to delete "${entity.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Optimistic delete - UI updates instantly
        await _optimisticService.deleteEntity(
          entityId: entity.id,
          apiCall: () async {
            await _supabase.from('entities').delete().eq('id', entity.id);
          },
        );
        entityCount.value--;
        Get.snackbar(
          'Success',
          'Entity deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete entity: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  /// Sign out admin
  Future<void> signOut() async {
    await _authRepository.signOut();
    Get.offAllNamed(AppRoutes.home);
  }

  /// Navigate to user management
  void goToUserManagement() {
    Get.toNamed(AppRoutes.userManagement);
  }
}

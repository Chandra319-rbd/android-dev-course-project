import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/optimistic_update_service.dart';
import '../../data/models/category_model.dart';
import '../../data/models/entity_model.dart';
import '../../data/providers/local_storage_provider.dart';
import '../../routes/app_routes.dart';

/// Controller for Category List Screen
class CategoryListController extends GetxController {
  final LocalStorageProvider _localStorage = Get.find<LocalStorageProvider>();
  final OptimisticUpdateService _optimisticService =
      Get.find<OptimisticUpdateService>();
  final ConnectivityService _connectivityService =
      Get.find<ConnectivityService>();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Category passed as argument
  late CategoryModel category;
  final RxString categoryId = ''.obs;

  // Observable states
  final RxList<EntityModel> entities = <EntityModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Connectivity state
  RxBool get isOnline => _connectivityService.isOnline;

  // Sort options
  final RxString sortBy = 'created_at'.obs;
  final RxBool sortAscending = false.obs;

  // Constructor - initialize with cached data immediately
  CategoryListController() {
    // Get category from arguments
    if (Get.arguments is CategoryModel) {
      category = Get.arguments as CategoryModel;
      categoryId.value = category.id;
    } else {
      // Try to get category ID from route parameters
      final id = Get.parameters['categoryId'];
      if (id != null) {
        categoryId.value = id;
        // Try to find category from cache
        final cachedCategory = _localStorage.getCategoryById(id);
        if (cachedCategory != null) {
          category = cachedCategory;
        } else {
          // Create a placeholder category
          category = CategoryModel(
            id: id,
            name: 'Category',
            iconName: 'category',
            color: '#C41E3A',
            createdAt: DateTime.now(),
          );
        }
      }
    }

    // Load cached entities immediately
    if (categoryId.value.isNotEmpty) {
      final cachedEntities = _optimisticService.getEntitiesByCategory(
        categoryId.value,
      );
      if (cachedEntities.isNotEmpty) {
        entities.assignAll(cachedEntities);
        _sortEntities();
      }
    }
  }

  @override
  void onInit() {
    super.onInit();

    // Start async loading (cached data is already set in constructor)
    _loadEntities();

    // Listen to global entity changes for instant updates
    ever(_optimisticService.entities, (_) => _updateEntitiesFromService());

    // Auto-refresh when back online
    _connectivityService.addOnlineCallback(_onBackOnline);
  }

  @override
  void onClose() {
    _connectivityService.removeOnlineCallback(_onBackOnline);
    super.onClose();
  }

  /// Called when device comes back online
  void _onBackOnline() {
    if (!isRefreshing.value && !isLoading.value) {
      refreshEntities();
    }
  }

  /// Update entities from optimistic service when global data changes
  void _updateEntitiesFromService() {
    if (categoryId.value.isEmpty) return;
    final categoryEntities = _optimisticService.getEntitiesByCategory(
      categoryId.value,
    );
    if (categoryEntities.isNotEmpty || entities.isNotEmpty) {
      entities.assignAll(categoryEntities);
      _sortEntities();
    }
  }

  /// Load entities for this category
  Future<void> _loadEntities() async {
    if (categoryId.value.isEmpty) return;

    // Only show loading on very first load with no cached data
    final hadCachedData = entities.isNotEmpty;
    if (!hadCachedData) {
      isLoading.value = true;
    }
    hasError.value = false;
    errorMessage.value = '';

    try {
      // Fetch from Supabase
      await _fetchEntities();
    } catch (e) {
      // Only show error if we have no data to display
      if (entities.isEmpty) {
        hasError.value = true;
        errorMessage.value =
            'Failed to load places. Please check your connection.';
      }
      // If we have cached data, fail silently and keep showing it
    } finally {
      if (!hadCachedData) {
        isLoading.value = false;
      }
    }
  }

  /// Fetch entities from Supabase and sync to optimistic service
  Future<void> _fetchEntities() async {
    try {
      final response = await _supabase
          .from('entities')
          .select('''
            *,
            entity_media(*)
          ''')
          .eq('category_id', categoryId.value)
          .order(sortBy.value, ascending: sortAscending.value);

      final List<EntityModel> fetchedEntities = (response as List)
          .map((json) => EntityModel.fromJson(json))
          .toList();

      entities.assignAll(fetchedEntities);

      // Save to local storage first
      await _localStorage.saveEntities(fetchedEntities);

      // Sync entities to optimistic service (for global cache) in parallel
      await Future.wait(
        fetchedEntities.map((entity) => _optimisticService.syncEntity(entity)),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh entities
  Future<void> refreshEntities() async {
    isRefreshing.value = true;
    hasError.value = false;

    try {
      await _fetchEntities();
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

  /// Retry loading
  Future<void> retryLoading() async {
    await _loadEntities();
  }

  /// Sort entities
  void _sortEntities() {
    final sorted = List<EntityModel>.from(entities);
    switch (sortBy.value) {
      case 'name':
        sorted.sort(
          (a, b) => sortAscending.value
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name),
        );
        break;
      case 'rating':
        sorted.sort((a, b) {
          final ratingA = a.averageRating ?? 0.0;
          final ratingB = b.averageRating ?? 0.0;
          return sortAscending.value
              ? ratingA.compareTo(ratingB)
              : ratingB.compareTo(ratingA);
        });
        break;
      case 'created_at':
        sorted.sort(
          (a, b) => sortAscending.value
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt),
        );
        break;
    }
    entities.assignAll(sorted);
  }

  /// Change sort option
  void changeSortBy(String value) {
    if (sortBy.value == value) {
      sortAscending.value = !sortAscending.value;
    } else {
      sortBy.value = value;
      sortAscending.value = true;
    }
    _sortEntities();
  }

  /// Navigate to entity detail
  void goToEntityDetail(EntityModel entity) {
    Get.toNamed(AppRoutes.entityDetailRoute(entity.id), arguments: entity);
  }
}

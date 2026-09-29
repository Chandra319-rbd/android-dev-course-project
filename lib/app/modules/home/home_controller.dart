import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/optimistic_update_service.dart';
import '../../data/models/category_model.dart';
import '../../data/models/entity_model.dart';
import '../../routes/app_routes.dart';

/// Controller for Home Screen
class HomeController extends GetxController {
  final OptimisticUpdateService _optimisticService =
      Get.find<OptimisticUpdateService>();
  final ConnectivityService _connectivityService =
      Get.find<ConnectivityService>();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Observable states - bind to optimistic service for instant updates
  RxList<CategoryModel> get categories => _optimisticService.categories;
  final RxList<EntityModel> featuredEntities = <EntityModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Connectivity state
  RxBool get isOnline => _connectivityService.isOnline;
  bool get isOfflineMode => !_connectivityService.isOnline.value;

  @override
  void onInit() {
    super.onInit();
    _loadData();

    // Listen to global entity changes for featured list
    ever(_optimisticService.entities, (_) => _updateFeaturedEntities());

    // Listen for connectivity changes to refresh data when back online
    _connectivityService.addOnlineCallback(_onBackOnline);
  }

  @override
  void onClose() {
    _connectivityService.removeOnlineCallback(_onBackOnline);
    super.onClose();
  }

  /// Called when device comes back online
  void _onBackOnline() {
    // Refresh data when connection is restored
    if (!isRefreshing.value && !isLoading.value) {
      refreshData();
    }
  }

  /// Update featured entities from global list
  void _updateFeaturedEntities() {
    featuredEntities.assignAll(
      _optimisticService.getFeaturedEntities(limit: 10),
    );
  }

  /// Load all data (categories and featured entities)
  Future<void> _loadData() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      // Show cached data immediately (optimistic)
      _loadFromCache();

      // Then fetch from Supabase in background
      await Future.wait([_fetchCategories(), _fetchFeaturedEntities()]);
    } catch (e) {
      // If network fails but we have cached data, show that
      if (categories.isEmpty) {
        hasError.value = true;
        errorMessage.value =
            'Failed to load data. Please check your connection.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Load data from local cache (instant display)
  void _loadFromCache() {
    // Categories are now managed by optimistic service
    // Just update featured entities from cache
    _updateFeaturedEntities();
  }

  /// Fetch categories from Supabase
  Future<void> _fetchCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name', ascending: true);

      final List<CategoryModel> fetchedCategories = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      // Sync to optimistic service (updates all listeners)
      await _optimisticService.syncCategories(fetchedCategories);
    } catch (e) {
      // Error will be handled by caller
      rethrow;
    }
  }

  /// Fetch featured entities from Supabase
  Future<void> _fetchFeaturedEntities() async {
    try {
      final response = await _supabase
          .from('entities')
          .select('''
            *,
            entity_media(*)
          ''')
          .order('created_at', ascending: false)
          .limit(10);

      final List<EntityModel> fetchedEntities = (response as List)
          .map((json) => EntityModel.fromJson(json))
          .toList();

      // Sync to optimistic service (updates all listeners)
      await _optimisticService.syncEntities(fetchedEntities);
      _updateFeaturedEntities();
    } catch (e) {
      // Error will be handled by caller
      rethrow;
    }
  }

  /// Refresh data (pull to refresh)
  Future<void> refreshData() async {
    isRefreshing.value = true;
    hasError.value = false;

    try {
      await Future.wait([_fetchCategories(), _fetchFeaturedEntities()]);
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

  /// Retry loading data
  Future<void> retryLoading() async {
    await _loadData();
  }

  /// Navigate to category list
  void goToCategory(CategoryModel category) {
    Get.toNamed(AppRoutes.categoryListRoute(category.id), arguments: category);
  }

  /// Navigate to entity detail
  void goToEntityDetail(EntityModel entity) {
    Get.toNamed(AppRoutes.entityDetailRoute(entity.id), arguments: entity);
  }

  /// Navigate to search screen
  void goToSearch({bool showAll = false}) {
    Get.toNamed(AppRoutes.search, arguments: {'showAll': showAll});
  }

  /// Navigate to profile screen
  void goToProfile() {
    Get.toNamed(AppRoutes.profile);
  }
}

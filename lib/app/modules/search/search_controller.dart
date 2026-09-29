import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/connectivity_service.dart';
import '../../data/models/entity_model.dart';
import '../../data/providers/local_storage_provider.dart';
import '../../routes/app_routes.dart';

/// Controller for Search Screen
class SearchController extends GetxController {
  final LocalStorageProvider _localStorage = Get.find<LocalStorageProvider>();
  final ConnectivityService _connectivityService =
      Get.find<ConnectivityService>();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Observable states
  final RxString searchQuery = ''.obs;
  final RxList<EntityModel> searchResults = <EntityModel>[].obs;
  final RxBool isSearching = false.obs;
  final RxBool hasSearched = false.obs;
  final RxBool isOfflineSearch = false.obs;

  // Recent searches (stored locally)
  final RxList<String> recentSearches = <String>[].obs;

  // Flag to show all entities
  final RxBool showingAll = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();

    // Check if we should show all entities
    final args = Get.arguments;
    if (args != null && args['showAll'] == true) {
      loadAllEntities();
    }
  }

  /// Load all entities (for "See All" functionality)
  Future<void> loadAllEntities() async {
    isSearching.value = true;
    hasSearched.value = true;
    showingAll.value = true;
    isOfflineSearch.value = false;

    // Check connectivity - if offline, load from cache
    if (!_connectivityService.isOnline.value) {
      _loadAllFromCache();
      isOfflineSearch.value = true;
      isSearching.value = false;
      return;
    }

    try {
      final response = await _supabase
          .from('entities')
          .select('''
            *,
            entity_media(*)
          ''')
          .order('name', ascending: true);

      final List<EntityModel> results = (response as List)
          .map((json) => EntityModel.fromJson(json))
          .toList();

      searchResults.assignAll(results);
    } catch (e) {
      // Fallback to local cache
      _loadAllFromCache();
      isOfflineSearch.value = true;
    } finally {
      isSearching.value = false;
    }
  }

  /// Load all entities from local cache
  void _loadAllFromCache() {
    final cachedEntities = _localStorage.getEntities();
    searchResults.assignAll(cachedEntities);
  }

  /// Load recent searches from local storage
  void _loadRecentSearches() {
    final saved = _localStorage.getSetting<List<dynamic>>('recentSearches');
    if (saved != null) {
      recentSearches.assignAll(saved.cast<String>());
    }
  }

  /// Save recent searches to local storage
  Future<void> _saveRecentSearches() async {
    await _localStorage.saveSetting('recentSearches', recentSearches.toList());
  }

  /// Add to recent searches
  void _addToRecentSearches(String query) {
    if (query.isEmpty) return;

    // Remove if already exists
    recentSearches.remove(query);

    // Add to beginning
    recentSearches.insert(0, query);

    // Keep only last 10
    if (recentSearches.length > 10) {
      recentSearches.removeLast();
    }

    _saveRecentSearches();
  }

  /// Search entities
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      hasSearched.value = false;
      return;
    }

    searchQuery.value = query;
    isSearching.value = true;
    hasSearched.value = true;
    isOfflineSearch.value = false;

    // Check connectivity - if offline, search locally immediately
    if (!_connectivityService.isOnline.value) {
      _searchLocal(query);
      isOfflineSearch.value = true;
      isSearching.value = false;
      return;
    }

    try {
      // Try online search first
      final response = await _supabase
          .from('entities')
          .select('''
            *,
            entity_media(*)
          ''')
          .ilike('name', '%$query%')
          .order('name', ascending: true)
          .limit(50);

      final List<EntityModel> results = (response as List)
          .map((json) => EntityModel.fromJson(json))
          .toList();

      searchResults.assignAll(results);

      // Add to recent searches if results found
      if (results.isNotEmpty) {
        _addToRecentSearches(query);
      }
    } catch (e) {
      // Fallback to local search
      _searchLocal(query);
      isOfflineSearch.value = true;
    } finally {
      isSearching.value = false;
    }
  }

  /// Search from local cache
  void _searchLocal(String query) {
    final cachedEntities = _localStorage.getEntities();
    final results = cachedEntities.where((entity) {
      final nameMatch = entity.name.toLowerCase().contains(query.toLowerCase());
      final descMatch =
          entity.description?.toLowerCase().contains(query.toLowerCase()) ??
          false;
      final addressMatch =
          entity.address?.toLowerCase().contains(query.toLowerCase()) ?? false;
      return nameMatch || descMatch || addressMatch;
    }).toList();

    searchResults.assignAll(results);

    if (results.isNotEmpty) {
      _addToRecentSearches(query);
    }
  }

  /// Clear search
  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    hasSearched.value = false;
    showingAll.value = false;
  }

  /// Remove from recent searches
  void removeRecentSearch(String query) {
    recentSearches.remove(query);
    _saveRecentSearches();
  }

  /// Clear all recent searches
  void clearRecentSearches() {
    recentSearches.clear();
    _saveRecentSearches();
  }

  /// Navigate to entity detail
  void goToEntityDetail(EntityModel entity) {
    Get.toNamed(AppRoutes.entityDetailRoute(entity.id), arguments: entity);
  }
}

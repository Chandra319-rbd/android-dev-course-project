import 'package:hive_flutter/hive_flutter.dart';
import '../models/category_model.dart';
import '../models/entity_model.dart';
import '../models/phone_number_model.dart';
import '../models/media_model.dart';
import '../models/profile_model.dart';
import '../models/review_model.dart';
import '../../core/constants/app_constants.dart';

/// Local storage provider using Hive for offline caching
class LocalStorageProvider {
  // Hive boxes
  Box<CategoryModel>? _categoriesBox;
  Box<EntityModel>? _entitiesBox;
  Box<dynamic>? _settingsBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    _registerAdapters();

    // Open boxes
    await _openBoxes();
  }

  /// Register Hive type adapters
  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(AppConstants.phoneNumberTypeId)) {
      Hive.registerAdapter(PhoneNumberModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.categoryTypeId)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.mediaTypeId)) {
      Hive.registerAdapter(MediaModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.entityTypeId)) {
      Hive.registerAdapter(EntityModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.profileTypeId)) {
      Hive.registerAdapter(ProfileModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.reviewTypeId)) {
      Hive.registerAdapter(ReviewModelAdapter());
    }
  }

  /// Open Hive boxes
  Future<void> _openBoxes() async {
    _categoriesBox = await Hive.openBox<CategoryModel>(
      AppConstants.categoriesBox,
    );
    _entitiesBox = await Hive.openBox<EntityModel>(AppConstants.entitiesBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
  }

  // ==================== Categories ====================

  /// Get all cached categories
  List<CategoryModel> getCategories() {
    return _categoriesBox?.values.toList() ?? [];
  }

  /// Get category by ID
  CategoryModel? getCategoryById(String id) {
    return _categoriesBox?.get(id);
  }

  /// Save categories to cache
  Future<void> saveCategories(List<CategoryModel> categories) async {
    final Map<String, CategoryModel> categoryMap = {
      for (var c in categories) c.id: c,
    };
    await _categoriesBox?.putAll(categoryMap);
  }

  /// Save single category
  Future<void> saveCategory(CategoryModel category) async {
    await _categoriesBox?.put(category.id, category);
  }

  /// Delete category from cache
  Future<void> deleteCategory(String id) async {
    await _categoriesBox?.delete(id);
  }

  /// Clear all categories
  Future<void> clearCategories() async {
    await _categoriesBox?.clear();
  }

  // ==================== Entities ====================

  /// Get all cached entities
  List<EntityModel> getEntities() {
    return _entitiesBox?.values.toList() ?? [];
  }

  /// Get entities by category ID
  List<EntityModel> getEntitiesByCategoryId(String categoryId) {
    return _entitiesBox?.values
            .where((e) => e.categoryId == categoryId)
            .toList() ??
        [];
  }

  /// Get entity by ID
  EntityModel? getEntityById(String id) {
    return _entitiesBox?.get(id);
  }

  /// Save entities to cache
  Future<void> saveEntities(List<EntityModel> entities) async {
    final Map<String, EntityModel> entityMap = {
      for (var e in entities) e.id: e,
    };
    await _entitiesBox?.putAll(entityMap);
  }

  /// Save single entity
  Future<void> saveEntity(EntityModel entity) async {
    await _entitiesBox?.put(entity.id, entity);
  }

  /// Delete entity from cache
  Future<void> deleteEntity(String id) async {
    await _entitiesBox?.delete(id);
  }

  /// Clear all entities
  Future<void> clearEntities() async {
    await _entitiesBox?.clear();
  }

  // ==================== Settings ====================

  /// Get setting value
  T? getSetting<T>(String key) {
    return _settingsBox?.get(key) as T?;
  }

  /// Save setting value
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }

  /// Delete setting
  Future<void> deleteSetting(String key) async {
    await _settingsBox?.delete(key);
  }

  // ==================== Cache Management ====================

  /// Get last sync time
  DateTime? getLastSyncTime(String key) {
    final timestamp = _settingsBox?.get('lastSync_$key') as int?;
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Set last sync time
  Future<void> setLastSyncTime(String key) async {
    await _settingsBox?.put(
      'lastSync_$key',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Check if cache is expired
  bool isCacheExpired(String key) {
    final lastSync = getLastSyncTime(key);
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > AppConstants.cacheDuration;
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await _categoriesBox?.clear();
    await _entitiesBox?.clear();
    await _settingsBox?.clear();
  }

  /// Close all boxes
  Future<void> close() async {
    await _categoriesBox?.close();
    await _entitiesBox?.close();
    await _settingsBox?.close();
  }
}

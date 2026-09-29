import 'package:get/get.dart';
import '../../data/models/category_model.dart';
import '../../data/models/entity_model.dart';
import '../../data/models/review_model.dart';
import '../../data/providers/local_storage_provider.dart';

/// Service for managing optimistic updates across the app
/// Provides instant UI feedback while syncing with backend
class OptimisticUpdateService extends GetxService {
  final LocalStorageProvider _localStorage = Get.find<LocalStorageProvider>();

  // Global reactive lists that controllers can listen to
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<EntityModel> entities = <EntityModel>[].obs;
  final RxMap<String, List<ReviewModel>> entityReviews =
      <String, List<ReviewModel>>{}.obs;

  // Pending operations for rollback
  final Map<String, _PendingOperation> _pendingOperations = {};

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
  }

  /// Load initial data from cache
  void _loadFromCache() {
    categories.assignAll(_localStorage.getCategories());
    entities.assignAll(_localStorage.getEntities());
  }

  // ==================== Categories ====================

  /// Optimistically add a category
  Future<CategoryModel?> addCategory({
    required CategoryModel category,
    required Future<CategoryModel> Function() apiCall,
  }) async {
    final operationId = 'add_category_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic update - add immediately
    categories.add(category);
    _localStorage.saveCategory(category);

    // Store for potential rollback
    _pendingOperations[operationId] = _PendingOperation(
      type: OperationType.add,
      rollback: () {
        categories.removeWhere((c) => c.id == category.id);
        _localStorage.deleteCategory(category.id);
      },
    );

    try {
      // Perform actual API call
      final result = await apiCall();

      // Update with server response (may have different ID or timestamps)
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        categories[index] = result;
        _localStorage.saveCategory(result);
      }

      _pendingOperations.remove(operationId);
      return result;
    } catch (e) {
      // Rollback on failure
      _pendingOperations[operationId]?.rollback();
      _pendingOperations.remove(operationId);
      rethrow;
    }
  }

  /// Optimistically update a category
  Future<CategoryModel?> updateCategory({
    required CategoryModel category,
    required Future<CategoryModel> Function() apiCall,
  }) async {
    final operationId =
        'update_category_${DateTime.now().millisecondsSinceEpoch}';

    // Store original for rollback
    final originalIndex = categories.indexWhere((c) => c.id == category.id);
    final original = originalIndex != -1
        ? categories[originalIndex].copyWith()
        : null;

    // Optimistic update
    if (originalIndex != -1) {
      categories[originalIndex] = category;
      _localStorage.saveCategory(category);
    }

    _pendingOperations[operationId] = _PendingOperation(
      type: OperationType.update,
      rollback: () {
        if (original != null && originalIndex != -1) {
          categories[originalIndex] = original;
          _localStorage.saveCategory(original);
        }
      },
    );

    try {
      final result = await apiCall();
      if (originalIndex != -1) {
        categories[originalIndex] = result;
        _localStorage.saveCategory(result);
      }
      _pendingOperations.remove(operationId);
      return result;
    } catch (e) {
      _pendingOperations[operationId]?.rollback();
      _pendingOperations.remove(operationId);
      rethrow;
    }
  }

  /// Optimistically delete a category
  Future<bool> deleteCategory({
    required String categoryId,
    required Future<void> Function() apiCall,
  }) async {
    final operationId =
        'delete_category_${DateTime.now().millisecondsSinceEpoch}';

    // Store original for rollback
    final originalIndex = categories.indexWhere((c) => c.id == categoryId);
    final original = originalIndex != -1 ? categories[originalIndex] : null;

    // Also store entities that belong to this category
    final categoryEntities = entities
        .where((e) => e.categoryId == categoryId)
        .toList();

    // Optimistic delete
    categories.removeWhere((c) => c.id == categoryId);
    entities.removeWhere((e) => e.categoryId == categoryId);
    _localStorage.deleteCategory(categoryId);
    for (var entity in categoryEntities) {
      _localStorage.deleteEntity(entity.id);
    }

    _pendingOperations[operationId] = _PendingOperation(
      type: OperationType.delete,
      rollback: () {
        if (original != null) {
          categories.add(original);
          _localStorage.saveCategory(original);
        }
        entities.addAll(categoryEntities);
        for (var entity in categoryEntities) {
          _localStorage.saveEntity(entity);
        }
      },
    );

    try {
      await apiCall();
      _pendingOperations.remove(operationId);
      return true;
    } catch (e) {
      _pendingOperations[operationId]?.rollback();
      _pendingOperations.remove(operationId);
      rethrow;
    }
  }

  // ==================== Entities ====================

  /// Optimistically add an entity
  Future<EntityModel?> addEntity({
    required EntityModel entity,
    required Future<EntityModel> Function() apiCall,
  }) async {
    final operationId = 'add_entity_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic update
    entities.insert(0, entity); // Insert at beginning (newest first)
    _localStorage.saveEntity(entity);

    _pendingOperations[operationId] = _PendingOperation(
      type: OperationType.add,
      rollback: () {
        entities.removeWhere((e) => e.id == entity.id);
        _localStorage.deleteEntity(entity.id);
      },
    );

    try {
      final result = await apiCall();
      final index = entities.indexWhere((e) => e.id == entity.id);
      if (index != -1) {
        entities[index] = result;
        _localStorage.saveEntity(result);
      }
      _pendingOperations.remove(operationId);
      return result;
    } catch (e) {
      _pendingOperations[operationId]?.rollback();
      _pendingOperations.remove(operationId);
      rethrow;
    }
  }

  /// Optimistically update an entity
  Future<EntityModel?> updateEntity({
    required EntityModel entity,
    required Future<EntityModel> Function() apiCall,
  }) async {
    final operationId =
        'update_entity_${DateTime.now().millisecondsSinceEpoch}';

    final originalIndex = entities.indexWhere((e) => e.id == entity.id);
    final original = originalIndex != -1
        ? entities[originalIndex].copyWith()
        : null;

    if (originalIndex != -1) {
      entities[originalIndex] = entity;
      _localStorage.saveEntity(entity);
    }

    _pendingOperations[operationId] = _PendingOperation(
      type: OperationType.update,
      rollback: () {
        if (original != null && originalIndex != -1) {
          entities[originalIndex] = original;
          _localStorage.saveEntity(original);
        }
      },
    );

    try {
      final result = await apiCall();
      if (originalIndex != -1) {
        entities[originalIndex] = result;
        _localStorage.saveEntity(result);
      }
      _pendingOperations.remove(operationId);
      return result;
    } catch (e) {
      _pendingOperations[operationId]?.rollback();
      _pendingOperations.remove(operationId);
      rethrow;
    }
  }

  /// Optimistically delete an entity
  Future<bool> deleteEntity({
    required String entityId,
    required Future<void> Function() apiCall,
  }) async {
    final operationId =
        'delete_entity_${DateTime.now().millisecondsSinceEpoch}';

    final originalIndex = entities.indexWhere((e) => e.id == entityId);
    final original = originalIndex != -1 ? entities[originalIndex] : null;

    entities.removeWhere((e) => e.id == entityId);
    _localStorage.deleteEntity(entityId);

    _pendingOperations[operationId] = _PendingOperation(
      type: OperationType.delete,
      rollback: () {
        if (original != null) {
          entities.add(original);
          _localStorage.saveEntity(original);
        }
      },
    );

    try {
      await apiCall();
      _pendingOperations.remove(operationId);
      return true;
    } catch (e) {
      _pendingOperations[operationId]?.rollback();
      _pendingOperations.remove(operationId);
      rethrow;
    }
  }

  // ==================== Reviews ====================

  /// Optimistically add a review
  Future<ReviewModel?> addReview({
    required String entityId,
    required ReviewModel review,
    required Future<ReviewModel?> Function() apiCall,
  }) async {
    final operationId = 'add_review_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic update
    final currentReviews = entityReviews[entityId] ?? [];
    entityReviews[entityId] = [review, ...currentReviews];

    // Update entity's average rating optimistically
    _updateEntityRating(entityId);

    _pendingOperations[operationId] = _PendingOperation(
      type: OperationType.add,
      rollback: () {
        final reviews = entityReviews[entityId] ?? [];
        reviews.removeWhere((r) => r.id == review.id);
        entityReviews[entityId] = reviews;
        _updateEntityRating(entityId);
      },
    );

    try {
      final result = await apiCall();
      if (result != null) {
        final reviews = entityReviews[entityId] ?? [];
        final index = reviews.indexWhere((r) => r.id == review.id);
        if (index != -1) {
          reviews[index] = result;
          entityReviews[entityId] = List.from(reviews);
        }
      }
      _pendingOperations.remove(operationId);
      return result;
    } catch (e) {
      _pendingOperations[operationId]?.rollback();
      _pendingOperations.remove(operationId);
      rethrow;
    }
  }

  /// Optimistically update a review
  Future<ReviewModel?> updateReview({
    required String entityId,
    required ReviewModel review,
    required Future<ReviewModel?> Function() apiCall,
  }) async {
    final operationId =
        'update_review_${DateTime.now().millisecondsSinceEpoch}';

    final reviews = entityReviews[entityId] ?? [];
    final originalIndex = reviews.indexWhere((r) => r.id == review.id);
    final original = originalIndex != -1 ? reviews[originalIndex] : null;

    if (originalIndex != -1) {
      reviews[originalIndex] = review;
      entityReviews[entityId] = List.from(reviews);
      _updateEntityRating(entityId);
    }

    _pendingOperations[operationId] = _PendingOperation(
      type: OperationType.update,
      rollback: () {
        if (original != null && originalIndex != -1) {
          final currentReviews = entityReviews[entityId] ?? [];
          if (originalIndex < currentReviews.length) {
            currentReviews[originalIndex] = original;
            entityReviews[entityId] = List.from(currentReviews);
            _updateEntityRating(entityId);
          }
        }
      },
    );

    try {
      final result = await apiCall();
      if (result != null && originalIndex != -1) {
        final currentReviews = entityReviews[entityId] ?? [];
        if (originalIndex < currentReviews.length) {
          currentReviews[originalIndex] = result;
          entityReviews[entityId] = List.from(currentReviews);
        }
      }
      _pendingOperations.remove(operationId);
      return result;
    } catch (e) {
      _pendingOperations[operationId]?.rollback();
      _pendingOperations.remove(operationId);
      rethrow;
    }
  }

  /// Optimistically delete a review
  Future<bool> deleteReview({
    required String entityId,
    required String reviewId,
    required Future<bool> Function() apiCall,
  }) async {
    final operationId =
        'delete_review_${DateTime.now().millisecondsSinceEpoch}';

    final reviews = entityReviews[entityId] ?? [];
    final originalIndex = reviews.indexWhere((r) => r.id == reviewId);
    final original = originalIndex != -1 ? reviews[originalIndex] : null;

    reviews.removeWhere((r) => r.id == reviewId);
    entityReviews[entityId] = List.from(reviews);
    _updateEntityRating(entityId);

    _pendingOperations[operationId] = _PendingOperation(
      type: OperationType.delete,
      rollback: () {
        if (original != null) {
          final currentReviews = entityReviews[entityId] ?? [];
          currentReviews.insert(
            originalIndex.clamp(0, currentReviews.length),
            original,
          );
          entityReviews[entityId] = List.from(currentReviews);
          _updateEntityRating(entityId);
        }
      },
    );

    try {
      final result = await apiCall();
      _pendingOperations.remove(operationId);
      return result;
    } catch (e) {
      _pendingOperations[operationId]?.rollback();
      _pendingOperations.remove(operationId);
      rethrow;
    }
  }

  /// Update entity rating based on reviews
  void _updateEntityRating(String entityId) {
    final reviews = entityReviews[entityId] ?? [];
    if (reviews.isEmpty) return;

    final totalRating = reviews.fold(0, (sum, r) => sum + r.rating);
    final avgRating = totalRating / reviews.length;

    final entityIndex = entities.indexWhere((e) => e.id == entityId);
    if (entityIndex != -1) {
      final entity = entities[entityIndex];
      entities[entityIndex] = entity.copyWith(
        averageRating: avgRating,
        reviewCount: reviews.length,
      );
    }
  }

  // ==================== Sync Methods ====================

  /// Sync categories from server
  Future<void> syncCategories(List<CategoryModel> serverCategories) async {
    categories.assignAll(serverCategories);
    await _localStorage.saveCategories(serverCategories);
  }

  /// Sync entities from server
  Future<void> syncEntities(List<EntityModel> serverEntities) async {
    entities.assignAll(serverEntities);
    await _localStorage.saveEntities(serverEntities);
  }

  /// Update single entity from server
  Future<void> syncEntity(EntityModel entity) async {
    final index = entities.indexWhere((e) => e.id == entity.id);
    if (index != -1) {
      entities[index] = entity;
    } else {
      entities.add(entity);
    }
    await _localStorage.saveEntity(entity);
  }

  /// Set reviews for an entity (after fetching from server)
  void setEntityReviews(String entityId, List<ReviewModel> reviews) {
    entityReviews[entityId] = reviews;
  }

  /// Get reviews for an entity
  List<ReviewModel> getEntityReviews(String entityId) {
    return entityReviews[entityId] ?? [];
  }

  /// Get entities by category
  List<EntityModel> getEntitiesByCategory(String categoryId) {
    return entities.where((e) => e.categoryId == categoryId).toList();
  }

  /// Get featured entities (most recent)
  List<EntityModel> getFeaturedEntities({int limit = 10}) {
    final sorted = List<EntityModel>.from(entities)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  /// Check if there are pending operations
  bool get hasPendingOperations => _pendingOperations.isNotEmpty;

  /// Get count of pending operations
  int get pendingOperationsCount => _pendingOperations.length;
}

/// Types of operations
enum OperationType { add, update, delete }

/// Represents a pending operation that can be rolled back
class _PendingOperation {
  final OperationType type;
  final Function rollback;

  _PendingOperation({required this.type, required this.rollback});
}

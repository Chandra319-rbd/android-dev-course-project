import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../providers/local_storage_provider.dart';

/// Repository for handling category operations with Supabase
class CategoryRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final LocalStorageProvider? _localStorage;

  CategoryRepository({LocalStorageProvider? localStorage})
    : _localStorage = localStorage;

  /// Get all categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('name', ascending: true);

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      // Cache the data
      _localStorage?.saveCategories(categories);

      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
      // Try to return cached data on error
      final cached = _localStorage?.getCategories();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  /// Get single category by ID
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return CategoryModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching category: $e');
      // Try cache
      return _localStorage?.getCategoryById(id);
    }
  }

  /// Create new category
  Future<CategoryModel> createCategory({
    required String name,
    required String iconName,
    required String color,
    String? imageUrl,
  }) async {
    try {
      final response = await _client
          .from('categories')
          .insert({
            'name': name,
            'icon_name': iconName,
            'color': color,
            'image_url': imageUrl,
          })
          .select()
          .single();

      final category = CategoryModel.fromJson(response);

      // Update cache
      _localStorage?.saveCategory(category);

      return category;
    } catch (e) {
      print('Error creating category: $e');
      rethrow;
    }
  }

  /// Update category
  Future<CategoryModel> updateCategory({
    required String id,
    String? name,
    String? iconName,
    String? color,
    String? imageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (iconName != null) updates['icon_name'] = iconName;
      if (color != null) updates['color'] = color;
      if (imageUrl != null) updates['image_url'] = imageUrl;

      final response = await _client
          .from('categories')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      final category = CategoryModel.fromJson(response);

      // Update cache
      _localStorage?.saveCategory(category);

      return category;
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    try {
      await _client.from('categories').delete().eq('id', id);

      // Remove from cache
      _localStorage?.deleteCategory(id);
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  /// Get category count
  Future<int> getCategoryCount() async {
    try {
      final response = await _client
          .from('categories')
          .select('id')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      print('Error getting category count: $e');
      return 0;
    }
  }

  /// Search categories by name
  Future<List<CategoryModel>> searchCategories(String query) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .ilike('name', '%$query%')
          .order('name', ascending: true);

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching categories: $e');
      return [];
    }
  }

  /// Get cached categories (offline support)
  List<CategoryModel> getCachedCategories() {
    return _localStorage?.getCategories() ?? [];
  }

  /// Clear category cache
  Future<void> clearCache() async {
    await _localStorage?.clearCategories();
  }
}

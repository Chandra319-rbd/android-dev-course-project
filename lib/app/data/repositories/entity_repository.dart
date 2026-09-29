import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entity_model.dart';
import '../models/phone_number_model.dart';
import '../providers/local_storage_provider.dart';

/// Repository for handling entity operations with Supabase
class EntityRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final LocalStorageProvider? _localStorage;

  EntityRepository({LocalStorageProvider? localStorage})
    : _localStorage = localStorage;

  /// Get all entities
  Future<List<EntityModel>> getEntities() async {
    try {
      final response = await _client
          .from('entities')
          .select('''
            *,
            entity_media(*)
          ''')
          .order('created_at', ascending: false);

      final entities = (response as List)
          .map((json) => EntityModel.fromJson(json))
          .toList();

      // Cache the data
      _localStorage?.saveEntities(entities);

      return entities;
    } catch (e) {
      print('Error fetching entities: $e');
      // Try to return cached data on error
      final cached = _localStorage?.getEntities();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  /// Get entities by category
  Future<List<EntityModel>> getEntitiesByCategory(String categoryId) async {
    try {
      final response = await _client
          .from('entities')
          .select('''
            *,
            entity_media(*)
          ''')
          .eq('category_id', categoryId)
          .order('name', ascending: true);

      final entities = (response as List)
          .map((json) => EntityModel.fromJson(json))
          .toList();

      return entities;
    } catch (e) {
      print('Error fetching entities by category: $e');
      // Try cache
      final cached = _localStorage?.getEntitiesByCategoryId(categoryId);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  /// Get single entity by ID
  Future<EntityModel?> getEntityById(String id) async {
    try {
      final response = await _client
          .from('entities')
          .select('''
            *,
            entity_media(*)
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return EntityModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching entity: $e');
      // Try cache
      return _localStorage?.getEntityById(id);
    }
  }

  /// Create new entity
  Future<EntityModel> createEntity({
    required String categoryId,
    required String name,
    String? description,
    String? address,
    List<PhoneNumberModel>? phoneNumbers,
    String? openingHours,
  }) async {
    try {
      final response = await _client
          .from('entities')
          .insert({
            'category_id': categoryId,
            'name': name,
            'description': description,
            'address': address,
            'phone_numbers':
                phoneNumbers?.map((p) => p.toJson()).toList() ?? [],
            'opening_hours': openingHours,
          })
          .select('''
            *,
            entity_media(*)
          ''')
          .single();

      final entity = EntityModel.fromJson(response);

      // Update cache
      _localStorage?.saveEntity(entity);

      return entity;
    } catch (e) {
      print('Error creating entity: $e');
      rethrow;
    }
  }

  /// Update entity
  Future<EntityModel> updateEntity({
    required String id,
    String? categoryId,
    String? name,
    String? description,
    String? address,
    List<PhoneNumberModel>? phoneNumbers,
    String? openingHours,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (categoryId != null) updates['category_id'] = categoryId;
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (address != null) updates['address'] = address;
      if (phoneNumbers != null) {
        updates['phone_numbers'] = phoneNumbers.map((p) => p.toJson()).toList();
      }
      if (openingHours != null) updates['opening_hours'] = openingHours;

      final response = await _client
          .from('entities')
          .update(updates)
          .eq('id', id)
          .select('''
            *,
            entity_media(*)
          ''')
          .single();

      final entity = EntityModel.fromJson(response);

      // Update cache
      _localStorage?.saveEntity(entity);

      return entity;
    } catch (e) {
      print('Error updating entity: $e');
      rethrow;
    }
  }

  /// Delete entity
  Future<void> deleteEntity(String id) async {
    try {
      await _client.from('entities').delete().eq('id', id);

      // Remove from cache
      _localStorage?.deleteEntity(id);
    } catch (e) {
      print('Error deleting entity: $e');
      rethrow;
    }
  }

  /// Get entity count
  Future<int> getEntityCount() async {
    try {
      final response = await _client
          .from('entities')
          .select('id')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      print('Error getting entity count: $e');
      return 0;
    }
  }

  /// Get entity count by category
  Future<int> getEntityCountByCategory(String categoryId) async {
    try {
      final response = await _client
          .from('entities')
          .select('id')
          .eq('category_id', categoryId)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      print('Error getting entity count by category: $e');
      return 0;
    }
  }

  /// Search entities by name
  Future<List<EntityModel>> searchEntities(String query) async {
    try {
      final response = await _client
          .from('entities')
          .select('''
            *,
            entity_media(*)
          ''')
          .or(
            'name.ilike.%$query%,description.ilike.%$query%,address.ilike.%$query%',
          )
          .order('name', ascending: true);

      return (response as List)
          .map((json) => EntityModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching entities: $e');
      return [];
    }
  }

  /// Get featured entities (most recent)
  Future<List<EntityModel>> getFeaturedEntities({int limit = 10}) async {
    try {
      final response = await _client
          .from('entities')
          .select('''
            *,
            entity_media(*)
          ''')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => EntityModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching featured entities: $e');
      return [];
    }
  }

  /// Get entities with reviews stats
  Future<List<EntityModel>> getEntitiesWithStats(String categoryId) async {
    try {
      // Get entities with their reviews for calculating average rating
      final response = await _client.rpc(
        'get_entities_with_stats',
        params: {'p_category_id': categoryId},
      );

      return (response as List)
          .map((json) => EntityModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback to regular query if RPC doesn't exist
      print('Error fetching entities with stats: $e');
      return getEntitiesByCategory(categoryId);
    }
  }

  /// Get cached entities (offline support)
  List<EntityModel> getCachedEntities() {
    return _localStorage?.getEntities() ?? [];
  }

  /// Get cached entities by category
  List<EntityModel> getCachedEntitiesByCategory(String categoryId) {
    return _localStorage?.getEntitiesByCategoryId(categoryId) ?? [];
  }

  /// Clear entity cache
  Future<void> clearCache() async {
    await _localStorage?.clearEntities();
  }
}

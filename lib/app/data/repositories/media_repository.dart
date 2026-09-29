import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/media_model.dart';

/// Repository for handling media operations with Supabase
class MediaRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Storage bucket names
  static const String imageBucket = 'entity-images';
  static const String videoBucket = 'entity-videos';
  static const String avatarBucket = 'avatars';

  /// Get all media for an entity
  Future<List<MediaModel>> getMediaForEntity(String entityId) async {
    try {
      final response = await _client
          .from('entity_media')
          .select()
          .eq('entity_id', entityId)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => MediaModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching media: $e');
      return [];
    }
  }

  /// Upload image for entity
  Future<MediaModel?> uploadImage({
    required String entityId,
    required File imageFile,
    bool isPrimary = false,
  }) async {
    try {
      final fileName = _generateFileName(entityId, imageFile.path, 'image');

      // Upload to storage
      await _client.storage
          .from(imageBucket)
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final publicUrl = _client.storage
          .from(imageBucket)
          .getPublicUrl(fileName);

      // Insert media record
      final response = await _client
          .from('entity_media')
          .insert({
            'entity_id': entityId,
            'media_url': publicUrl,
            'media_type': 'image',
            'is_primary': isPrimary,
            'uploaded_by': _client.auth.currentUser?.id,
          })
          .select()
          .single();

      return MediaModel.fromJson(response);
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload video for entity
  Future<MediaModel?> uploadVideo({
    required String entityId,
    required File videoFile,
  }) async {
    try {
      final fileName = _generateFileName(entityId, videoFile.path, 'video');

      // Upload to storage
      await _client.storage
          .from(videoBucket)
          .upload(
            fileName,
            videoFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final publicUrl = _client.storage
          .from(videoBucket)
          .getPublicUrl(fileName);

      // Insert media record
      final response = await _client
          .from('entity_media')
          .insert({
            'entity_id': entityId,
            'media_url': publicUrl,
            'media_type': 'video',
            'is_primary': false,
            'uploaded_by': _client.auth.currentUser?.id,
          })
          .select()
          .single();

      return MediaModel.fromJson(response);
    } catch (e) {
      print('Error uploading video: $e');
      rethrow;
    }
  }

  /// Upload avatar for user profile
  Future<String?> uploadAvatar({
    required String userId,
    required File avatarFile,
  }) async {
    try {
      final fileName =
          'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to storage
      await _client.storage
          .from(avatarBucket)
          .upload(
            fileName,
            avatarFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      return _client.storage.from(avatarBucket).getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading avatar: $e');
      rethrow;
    }
  }

  /// Delete media
  Future<void> deleteMedia(MediaModel media) async {
    try {
      // Delete from storage
      final bucket = media.isImage ? imageBucket : videoBucket;
      final fileName = _extractFileName(media.mediaUrl);

      if (fileName != null) {
        await _client.storage.from(bucket).remove([fileName]);
      }

      // Delete record from database
      await _client.from('entity_media').delete().eq('id', media.id);
    } catch (e) {
      print('Error deleting media: $e');
      rethrow;
    }
  }

  /// Set media as primary
  Future<void> setPrimaryMedia({
    required String entityId,
    required String mediaId,
  }) async {
    try {
      // First, set all media for entity as non-primary
      await _client
          .from('entity_media')
          .update({'is_primary': false})
          .eq('entity_id', entityId);

      // Then set the selected one as primary
      await _client
          .from('entity_media')
          .update({'is_primary': true})
          .eq('id', mediaId);
    } catch (e) {
      print('Error setting primary media: $e');
      rethrow;
    }
  }

  /// Upload multiple images
  Future<List<MediaModel>> uploadMultipleImages({
    required String entityId,
    required List<File> imageFiles,
    int primaryIndex = 0,
  }) async {
    final List<MediaModel> uploadedMedia = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final media = await uploadImage(
        entityId: entityId,
        imageFile: imageFiles[i],
        isPrimary: i == primaryIndex,
      );
      if (media != null) {
        uploadedMedia.add(media);
      }
    }

    return uploadedMedia;
  }

  /// Delete all media for an entity
  Future<void> deleteAllMediaForEntity(String entityId) async {
    try {
      final media = await getMediaForEntity(entityId);

      for (var item in media) {
        await deleteMedia(item);
      }
    } catch (e) {
      print('Error deleting all media: $e');
      rethrow;
    }
  }

  /// Generate unique file name
  String _generateFileName(String entityId, String filePath, String type) {
    final extension = filePath.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${entityId}_${timestamp}_$type.$extension';
  }

  /// Extract file name from URL
  String? _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.last;
    } catch (e) {
      return null;
    }
  }

  /// Get signed URL for private media (if needed)
  Future<String?> getSignedUrl(String bucket, String path) async {
    try {
      final response = await _client.storage
          .from(bucket)
          .createSignedUrl(
            path,
            60 * 60, // 1 hour expiry
          );
      return response;
    } catch (e) {
      print('Error getting signed URL: $e');
      return null;
    }
  }
}

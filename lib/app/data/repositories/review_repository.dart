import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

/// Repository for handling review operations with Supabase
class ReviewRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get all reviews for an entity
  Future<List<ReviewModel>> getReviewsForEntity(String entityId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('''
            *,
            profiles(full_name, avatar_url),
            review_media(media_url)
          ''')
          .eq('entity_id', entityId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  /// Get a user's review for a specific entity
  Future<ReviewModel?> getUserReviewForEntity({
    required String entityId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('reviews')
          .select('''
            *,
            profiles(full_name, avatar_url),
            review_media(media_url)
          ''')
          .eq('entity_id', entityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return ReviewModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching user review: $e');
      return null;
    }
  }

  /// Create a new review
  Future<ReviewModel?> createReview({
    required String entityId,
    required String userId,
    required int rating,
    String? comment,
    List<File>? images,
  }) async {
    try {
      // 1. Insert review
      final response = await _client
          .from('reviews')
          .insert({
            'entity_id': entityId,
            'user_id': userId,
            'rating': rating,
            'comment': comment,
          })
          .select('''
            *,
            profiles(full_name, avatar_url)
          ''')
          .single();

      final review = ReviewModel.fromJson(response);

      // 2. Upload images if any
      if (images != null && images.isNotEmpty) {
        await _uploadReviewImages(review.id, images);

        // Fetch the review again to get the media URLs
        final updatedResponse = await _client
            .from('reviews')
            .select('''
              *,
              profiles(full_name, avatar_url),
              review_media(media_url)
            ''')
            .eq('id', review.id)
            .single();

        return ReviewModel.fromJson(updatedResponse);
      }

      return review;
    } catch (e) {
      print('Error creating review: $e');
      rethrow;
    }
  }

  /// Upload images for a review
  Future<void> _uploadReviewImages(String reviewId, List<File> images) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('Error uploading images: User not logged in');
      return;
    }

    for (var image in images) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = image.path.split('.').last;
        final fileName = '${reviewId}_$timestamp.$extension';
        final path = '$userId/$fileName';
        const bucket = 'review-images';

        // Upload to storage
        await _client.storage
            .from(bucket)
            .upload(path, image, fileOptions: const FileOptions(upsert: true));

        // Get public URL
        final publicUrl = _client.storage.from(bucket).getPublicUrl(path);

        // Insert media record
        await _client.from('review_media').insert({
          'review_id': reviewId,
          'media_url': publicUrl,
          'media_type': 'image',
          'uploaded_by': userId,
        });
      } catch (e) {
        print('Error uploading review image: $e');
      }
    }
  }

  /// Update an existing review
  Future<ReviewModel?> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
    List<File>? images,
    List<String>? keptImageUrls,
  }) async {
    try {
      // 1. Update review details
      await _client
          .from('reviews')
          .update({
            'rating': rating,
            'comment': comment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId);

      // 2. Handle image deletions
      if (keptImageUrls != null) {
        // Get current media for this review
        final currentMedia = await _client
            .from('review_media')
            .select('id, media_url')
            .eq('review_id', reviewId);

        final currentMediaList = currentMedia as List;

        for (var item in currentMediaList) {
          final url = item['media_url'] as String;
          if (!keptImageUrls.contains(url)) {
            // Delete from storage
            try {
              // Extract path from URL
              // URL format: .../storage/v1/object/public/review-images/userId/filename
              // We need to extract 'userId/filename'
              final uri = Uri.parse(url);
              final pathSegments = uri.pathSegments;

              // Find the index of the bucket name in the segments
              final bucketIndex = pathSegments.indexOf('review-images');
              if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
                final path = pathSegments.sublist(bucketIndex + 1).join('/');
                await _client.storage.from('review-images').remove([path]);
              }
            } catch (e) {
              print('Error deleting image from storage: $e');
            }
            // Delete from database
            await _client.from('review_media').delete().eq('id', item['id']);
          }
        }
      }

      // 3. Upload new images if any
      if (images != null && images.isNotEmpty) {
        await _uploadReviewImages(reviewId, images);
      }

      // 4. Fetch updated review with all data including media
      final response = await _client
          .from('reviews')
          .select('''
            *,
            profiles(full_name, avatar_url),
            review_media(media_url)
          ''')
          .eq('id', reviewId)
          .single();

      return ReviewModel.fromJson(response);
    } catch (e) {
      print('Error updating review: $e');
      rethrow;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _client.from('reviews').delete().eq('id', reviewId);
      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  /// Get all reviews by a user
  Future<List<ReviewModel>> getReviewsByUser(String userId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('''
            *,
            profiles(full_name, avatar_url),
            entities(name)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching user reviews: $e');
      return [];
    }
  }

  /// Get average rating for an entity
  Future<double> getAverageRating(String entityId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('rating')
          .eq('entity_id', entityId);

      if ((response as List).isEmpty) return 0.0;

      final total = response.fold<int>(
        0,
        (sum, review) => sum + (review['rating'] as int),
      );
      return total / response.length;
    } catch (e) {
      print('Error calculating average rating: $e');
      return 0.0;
    }
  }

  /// Get review count for an entity
  Future<int> getReviewCount(String entityId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('id')
          .eq('entity_id', entityId);

      return (response as List).length;
    } catch (e) {
      print('Error getting review count: $e');
      return 0;
    }
  }

  /// Check if user has already reviewed an entity
  Future<bool> hasUserReviewed({
    required String entityId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('reviews')
          .select('id')
          .eq('entity_id', entityId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking user review: $e');
      return false;
    }
  }
}

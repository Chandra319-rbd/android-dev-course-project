/// Supabase configuration constants
class SupabaseConstants {
  SupabaseConstants._();

  // Supabase Project URL
  // Get this from: Supabase Dashboard > Settings > API > Project URL

  static const String supabaseUrl = 'https://wkwrhnvbunvvmdczxter.supabase.co';

  // Supabase Anon Key
  // Get this from: Supabase Dashboard > Settings > API > Project API keys > anon public
  static const String supabaseAnonKey =
      'sb_publishable_kJfc1SsRfpOl-PZ-nFet5Q_6phcw31e';

  // Table Names
  static const String categoriesTable = 'categories';
  static const String entitiesTable = 'entities';
  static const String entityMediaTable = 'entity_media';
  static const String profilesTable = 'profiles';
  static const String reviewsTable = 'reviews';

  // Storage Bucket Names
  static const String entityImagesBucket = 'entity-images';
  static const String entityVideosBucket = 'entity-videos';
  static const String avatarsBucket = 'avatars';

  // Storage Paths
  static String entityImagePath(String entityId, String fileName) =>
      '$entityId/$fileName';

  static String entityVideoPath(String entityId, String fileName) =>
      '$entityId/$fileName';

  static String avatarPath(String userId, String fileName) =>
      '$userId/$fileName';
}

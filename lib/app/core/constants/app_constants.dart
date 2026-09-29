/// App-wide constants for Village Explorer
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Village Explorer';
  static const String appNameChinese = '村庄探索';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  static const String categoriesBox = 'categories_box';
  static const String entitiesBox = 'entities_box';
  static const String settingsBox = 'settings_box';

  // Hive Type IDs
  static const int categoryTypeId = 0;
  static const int entityTypeId = 1;
  static const int mediaTypeId = 2;
  static const int profileTypeId = 3;
  static const int reviewTypeId = 4;
  static const int phoneNumberTypeId = 5;

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 24);

  // Pagination
  static const int defaultPageSize = 20;

  // Image Sizes
  static const double thumbnailSize = 100;
  static const double cardImageHeight = 150;
  static const double detailImageHeight = 250;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // Border Radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusRound = 100;

  // Rating
  static const int maxRating = 5;
  static const int minRating = 1;
}

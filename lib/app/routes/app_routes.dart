/// Route names for Village Explorer app
abstract class AppRoutes {
  AppRoutes._();

  // Main routes
  static const String splash = '/splash';
  static const String home = '/home';

  // Category routes
  static const String categoryList = '/category/:categoryId';
  static const String entityDetail = '/entity/:entityId';

  // Search
  static const String search = '/search';

  // Auth routes
  static const String login = '/login';
  static const String profile = '/profile';

  // Admin routes
  static const String adminDashboard = '/admin';
  static const String categoryForm = '/admin/category';
  static const String entityForm = '/admin/entity';
  static const String userManagement = '/admin/users';

  // Helper methods to build routes with parameters
  static String categoryListRoute(String categoryId) => '/category/$categoryId';
  static String entityDetailRoute(String entityId) => '/entity/$entityId';
}

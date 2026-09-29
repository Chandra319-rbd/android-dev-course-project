import 'package:get/get.dart';
import 'app_routes.dart';

// Phase 2 - Core Screens
import '../modules/splash/splash_page.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/home/home_page.dart';
import '../modules/home/home_binding.dart';
import '../modules/category/category_list_page.dart';
import '../modules/category/category_list_binding.dart';
import '../modules/entity_detail/entity_detail_page.dart';
import '../modules/entity_detail/entity_detail_binding.dart';
import '../modules/search/search_page.dart';
import '../modules/search/search_binding.dart';

// Phase 3 - Auth & Profile
import '../modules/auth/login_page.dart';
import '../modules/auth/login_binding.dart';
import '../modules/profile/profile_page.dart';
import '../modules/profile/profile_binding.dart';

// Phase 5 - Admin Dashboard
import '../modules/admin/dashboard/admin_dashboard_page.dart';
import '../modules/admin/dashboard/admin_dashboard_binding.dart';
import '../modules/admin/category_form/category_form_page.dart';
import '../modules/admin/category_form/category_form_binding.dart';
import '../modules/admin/entity_form/entity_form_page.dart';
import '../modules/admin/entity_form/entity_form_binding.dart';
import '../modules/admin/user_management/user_management_page.dart';
import '../modules/admin/user_management/user_management_binding.dart';

/// Page configurations for GetX routing
class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final List<GetPage> pages = [
    // Splash Screen
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
      transition: Transition.fade,
    ),

    // Home Screen
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),

    // Category List Screen
    GetPage(
      name: AppRoutes.categoryList,
      page: () => const CategoryListPage(),
      binding: CategoryListBinding(),
    ),

    // Entity Detail Screen
    GetPage(
      name: AppRoutes.entityDetail,
      page: () => const EntityDetailPage(),
      binding: EntityDetailBinding(),
    ),

    // Search Screen
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchPage(),
      binding: SearchBinding(),
    ),

    // Login Screen
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),

    // Profile Screen
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
    ),

    // Admin Dashboard
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminDashboardPage(),
      binding: AdminDashboardBinding(),
    ),

    // Category Form (Add/Edit)
    GetPage(
      name: AppRoutes.categoryForm,
      page: () => const CategoryFormPage(),
      binding: CategoryFormBinding(),
    ),

    // Entity Form (Add/Edit)
    GetPage(
      name: AppRoutes.entityForm,
      page: () => const EntityFormPage(),
      binding: EntityFormBinding(),
    ),

    // User Management (Admin)
    GetPage(
      name: AppRoutes.userManagement,
      page: () => const UserManagementPage(),
      binding: UserManagementBinding(),
    ),
  ];
}

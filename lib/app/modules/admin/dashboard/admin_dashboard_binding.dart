import 'package:get/get.dart';
import 'admin_dashboard_controller.dart';
import '../../../data/repositories/auth_repository.dart';

/// Binding for Admin Dashboard
class AdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure AuthRepository is available
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put(AuthRepository());
    }

    Get.lazyPut<AdminDashboardController>(() => AdminDashboardController());
  }
}

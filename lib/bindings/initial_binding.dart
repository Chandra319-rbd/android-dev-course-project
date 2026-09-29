import 'package:get/get.dart';
import '../app/core/services/connectivity_service.dart';
import '../app/core/services/optimistic_update_service.dart';
import '../app/data/repositories/auth_repository.dart';
import '../app/modules/auth/auth_controller.dart';

/// Initial binding that registers global controllers and services
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Local Storage Provider is already initialized and put in main.dart
    // Get.put<LocalStorageProvider>(LocalStorageProvider(), permanent: true);

    // Connectivity Service (singleton - monitors network state)
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);

    // Optimistic Update Service (singleton - manages instant UI updates)
    Get.put<OptimisticUpdateService>(
      OptimisticUpdateService(),
      permanent: true,
    );

    // Auth Repository (singleton)
    Get.put<AuthRepository>(AuthRepository(), permanent: true);

    // Auth Controller (singleton - manages global auth state)
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}

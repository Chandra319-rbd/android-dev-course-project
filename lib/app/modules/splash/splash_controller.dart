import 'package:get/get.dart';
import '../../data/providers/local_storage_provider.dart';
import '../../routes/app_routes.dart';

/// Controller for Splash Screen
class SplashController extends GetxController {
  final LocalStorageProvider _localStorage = Get.find<LocalStorageProvider>();

  // Loading state
  final RxBool isLoading = true.obs;
  final RxString loadingText = 'Loading...'.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  /// Initialize app and navigate to home
  Future<void> _initializeApp() async {
    try {
      // Step 1: Load cached data
      loadingText.value = 'Loading cached data...';
      await Future.delayed(const Duration(milliseconds: 500));

      // Load categories from cache
      final cachedCategories = _localStorage.getCategories();
      if (cachedCategories.isNotEmpty) {
        loadingText.value = 'Found ${cachedCategories.length} categories...';
      }

      // Step 2: Check for updates (simulated)
      loadingText.value = 'Checking for updates...';
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Ready to go
      loadingText.value = 'Welcome!';
      await Future.delayed(const Duration(milliseconds: 300));

      isLoading.value = false;

      // Navigate to home
      _navigateToHome();
    } catch (e) {
      loadingText.value = 'Error loading app';
      await Future.delayed(const Duration(seconds: 1));
      _navigateToHome();
    }
  }

  /// Navigate to home screen
  void _navigateToHome() {
    Get.offAllNamed(AppRoutes.home);
  }
}

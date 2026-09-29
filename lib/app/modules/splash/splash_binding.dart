import 'package:get/get.dart';
import 'splash_controller.dart';

/// Binding for Splash Screen
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}

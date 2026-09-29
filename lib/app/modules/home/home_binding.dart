import 'package:get/get.dart';
import 'home_controller.dart';

/// Binding for Home Screen
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}

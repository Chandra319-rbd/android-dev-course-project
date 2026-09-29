import 'package:get/get.dart';
import 'login_controller.dart';

/// Binding for Login page
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}

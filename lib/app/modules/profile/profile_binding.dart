import 'package:get/get.dart';
import 'profile_controller.dart';

/// Binding for Profile page
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}

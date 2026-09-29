import 'package:get/get.dart';
import 'category_form_controller.dart';

/// Binding for Category Form
class CategoryFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryFormController>(() => CategoryFormController());
  }
}

import 'package:get/get.dart';
import 'category_list_controller.dart';

/// Binding for Category List Screen
class CategoryListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryListController>(() => CategoryListController());
  }
}

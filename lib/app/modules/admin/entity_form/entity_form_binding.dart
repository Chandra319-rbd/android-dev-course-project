import 'package:get/get.dart';
import 'entity_form_controller.dart';

/// Binding for Entity Form
class EntityFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EntityFormController>(() => EntityFormController());
  }
}

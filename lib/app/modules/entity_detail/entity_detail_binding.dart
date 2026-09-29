import 'package:get/get.dart';
import 'entity_detail_controller.dart';

/// Binding for Entity Detail Screen
class EntityDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EntityDetailController>(() => EntityDetailController());
  }
}

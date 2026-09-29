import 'package:get/get.dart';
import 'search_controller.dart' as search;

/// Binding for Search Screen
class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<search.SearchController>(() => search.SearchController());
  }
}

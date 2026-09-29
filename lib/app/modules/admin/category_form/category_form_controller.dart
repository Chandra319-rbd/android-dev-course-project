import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/optimistic_update_service.dart';
import '../../../data/models/category_model.dart';

/// Controller for Category Form (Add/Edit)
class CategoryFormController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final OptimisticUpdateService _optimisticService =
      Get.find<OptimisticUpdateService>();
  final Uuid _uuid = const Uuid();

  // Form key
  final formKey = GlobalKey<FormState>();

  // Text controllers
  final nameController = TextEditingController();

  // Observable states
  final RxString selectedIconName = 'category'.obs;
  final RxString selectedColor = '#C41E3A'.obs;
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final Rxn<CategoryModel> editingCategory = Rxn<CategoryModel>();

  // Available icons
  final List<Map<String, dynamic>> availableIcons = [
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Restaurant'},
    {'name': 'hotel', 'icon': Icons.hotel, 'label': 'Hotel'},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag, 'label': 'Shopping'},
    {'name': 'local_cafe', 'icon': Icons.local_cafe, 'label': 'Cafe'},
    {'name': 'spa', 'icon': Icons.spa, 'label': 'Spa'},
    {
      'name': 'sports_esports',
      'icon': Icons.sports_esports,
      'label': 'Entertainment',
    },
    {'name': 'museum', 'icon': Icons.museum, 'label': 'Museum'},
    {'name': 'park', 'icon': Icons.park, 'label': 'Park'},
    {'name': 'beach_access', 'icon': Icons.beach_access, 'label': 'Beach'},
    {
      'name': 'temple_buddhist',
      'icon': Icons.temple_buddhist,
      'label': 'Temple',
    },
    {'name': 'church', 'icon': Icons.church, 'label': 'Church'},
    {'name': 'mosque', 'icon': Icons.mosque, 'label': 'Mosque'},
    {
      'name': 'local_hospital',
      'icon': Icons.local_hospital,
      'label': 'Hospital',
    },
    {'name': 'school', 'icon': Icons.school, 'label': 'School'},
    {
      'name': 'local_gas_station',
      'icon': Icons.local_gas_station,
      'label': 'Gas Station',
    },
    {'name': 'local_parking', 'icon': Icons.local_parking, 'label': 'Parking'},
    {'name': 'local_atm', 'icon': Icons.local_atm, 'label': 'ATM'},
    {
      'name': 'local_pharmacy',
      'icon': Icons.local_pharmacy,
      'label': 'Pharmacy',
    },
    {'name': 'category', 'icon': Icons.category, 'label': 'Category'},
    {'name': 'place', 'icon': Icons.place, 'label': 'Place'},
    {'name': 'store', 'icon': Icons.store, 'label': 'Store'},
    {'name': 'home', 'icon': Icons.home, 'label': 'Home'},
    {'name': 'business', 'icon': Icons.business, 'label': 'Business'},
    {'name': 'local_library', 'icon': Icons.local_library, 'label': 'Library'},
  ];

  // Available colors (Chinese-style palette)
  final List<Map<String, String>> availableColors = [
    {'hex': '#C41E3A', 'name': 'Chinese Red'},
    {'hex': '#E85A6B', 'name': 'Light Red'},
    {'hex': '#8B1528', 'name': 'Dark Red'},
    {'hex': '#FFD700', 'name': 'Imperial Gold'},
    {'hex': '#00A86B', 'name': 'Jade Green'},
    {'hex': '#4DC99A', 'name': 'Light Jade'},
    {'hex': '#007A4D', 'name': 'Dark Jade'},
    {'hex': '#2E4A62', 'name': 'Indigo Blue'},
    {'hex': '#E34234', 'name': 'Cinnabar'},
    {'hex': '#7BA05B', 'name': 'Bamboo Green'},
    {'hex': '#9B59B6', 'name': 'Purple'},
    {'hex': '#F39C12', 'name': 'Orange'},
    {'hex': '#1ABC9C', 'name': 'Teal'},
    {'hex': '#34495E', 'name': 'Navy'},
    {'hex': '#E91E63', 'name': 'Pink'},
    {'hex': '#795548', 'name': 'Brown'},
  ];

  @override
  void onInit() {
    super.onInit();
    // Check if editing existing category
    final arguments = Get.arguments;
    if (arguments is CategoryModel) {
      isEditing.value = true;
      editingCategory.value = arguments;
      _populateForm(arguments);
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  /// Populate form with existing category data
  void _populateForm(CategoryModel category) {
    nameController.text = category.name;
    selectedIconName.value = category.iconName;
    selectedColor.value = category.color;
  }

  /// Select icon
  void selectIcon(String iconName) {
    selectedIconName.value = iconName;
  }

  /// Select color
  void selectColor(String colorHex) {
    selectedColor.value = colorHex;
  }

  /// Validate and save category with optimistic update
  Future<void> saveCategory() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      if (isEditing.value) {
        await _updateCategory();
      } else {
        await _createCategory();
      }

      Get.back(result: true);
      Get.snackbar(
        'Success',
        isEditing.value
            ? 'Category updated successfully'
            : 'Category created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save category: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Create new category with optimistic update
  Future<void> _createCategory() async {
    // Create optimistic category with temp ID
    final tempId = _uuid.v4();
    final optimisticCategory = CategoryModel(
      id: tempId,
      name: nameController.text.trim(),
      iconName: selectedIconName.value,
      color: selectedColor.value,
      createdAt: DateTime.now(),
    );

    // Optimistic update - add to UI instantly
    await _optimisticService.addCategory(
      category: optimisticCategory,
      apiCall: () async {
        final response = await _supabase
            .from('categories')
            .insert({
              'name': nameController.text.trim(),
              'icon_name': selectedIconName.value,
              'color': selectedColor.value,
            })
            .select()
            .single();

        return CategoryModel.fromJson(response);
      },
    );
  }

  /// Update existing category with optimistic update
  Future<void> _updateCategory() async {
    final updatedCategory = editingCategory.value!.copyWith(
      name: nameController.text.trim(),
      iconName: selectedIconName.value,
      color: selectedColor.value,
    );

    // Optimistic update - update UI instantly
    await _optimisticService.updateCategory(
      category: updatedCategory,
      apiCall: () async {
        final response = await _supabase
            .from('categories')
            .update({
              'name': nameController.text.trim(),
              'icon_name': selectedIconName.value,
              'color': selectedColor.value,
            })
            .eq('id', editingCategory.value!.id)
            .select()
            .single();

        return CategoryModel.fromJson(response);
      },
    );
  }

  /// Delete category with optimistic update
  Future<void> deleteCategory() async {
    if (editingCategory.value == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${editingCategory.value!.name}"? '
          'This will also delete all entities in this category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      isLoading.value = true;
      try {
        // Optimistic delete - remove from UI instantly
        await _optimisticService.deleteCategory(
          categoryId: editingCategory.value!.id,
          apiCall: () async {
            await _supabase
                .from('categories')
                .delete()
                .eq('id', editingCategory.value!.id);
          },
        );

        Get.back(result: true);
        Get.snackbar(
          'Success',
          'Category deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete category: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  /// Get IconData from icon name
  IconData getIconData(String iconName) {
    final found = availableIcons.firstWhereOrNull(
      (icon) => icon['name'] == iconName,
    );
    return found?['icon'] ?? Icons.category;
  }

  /// Parse color from hex string
  Color parseColor(String hexString) {
    try {
      String hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return const Color(0xFFC41E3A);
    }
  }
}

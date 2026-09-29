import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'entity_form_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/opening_hours/opening_hours_widget.dart';
import '../../../data/models/local/media_item.dart';

/// Entity Form Page (Add/Edit)
class EntityFormPage extends GetView<EntityFormController> {
  const EntityFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.chineseRed),
                SizedBox(height: 16),
                Text(
                  'Saving...',
                  style: TextStyle(color: AppColors.mediumGray),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryDropdown(),
                const SizedBox(height: 20),
                _buildNameField(),
                const SizedBox(height: 20),
                _buildDescriptionField(),
                const SizedBox(height: 20),
                _buildAddressField(),
                const SizedBox(height: 20),
                _buildOpeningHoursField(),
                const SizedBox(height: 20),
                _buildPhoneNumbersSection(),
                const SizedBox(height: 20),
                _buildMediaSection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                if (controller.isEditing.value) ...[
                  const SizedBox(height: 16),
                  _buildDeleteButton(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Obx(
        () => Text(
          controller.isEditing.value ? 'Edit Entity' : 'Add Entity',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      backgroundColor: AppColors.chineseRed,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  /// Build category dropdown
  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isCategoriesLoading.value) {
            return Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.chineseRed,
                  ),
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: DropdownButtonFormField<String>(
              value: controller.selectedCategoryId.value,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              hint: const Text('Select a category'),
              items: controller.categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: controller.selectCategory,
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
          );
        }),
      ],
    );
  }

  /// Build name field
  Widget _buildNameField() {
    return _buildTextField(
      label: 'Name *',
      controller: controller.nameController,
      hint: 'Enter entity name',
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a name';
        }
        return null;
      },
    );
  }

  /// Build description field
  Widget _buildDescriptionField() {
    return _buildTextField(
      label: 'Description',
      controller: controller.descriptionController,
      hint: 'Enter description (optional)',
      maxLines: 4,
    );
  }

  /// Build address field
  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Address & Location',
          controller: controller.addressController,
          hint: 'Enter address or pick on map',
          maxLines: 2,
          suffixIcon: IconButton(
            icon: const Icon(Icons.map_rounded, color: AppColors.chineseRed),
            tooltip: 'Pick on Map',
            onPressed: controller.pickLocation,
          ),
        ),
        // Show coordinates if selected
        Obx(() {
          if (controller.latitude.value != null &&
              controller.longitude.value != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Location coordinates set (${controller.latitude.value!.toStringAsFixed(4)}, ${controller.longitude.value!.toStringAsFixed(4)})',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  /// Build opening hours field with time pickers
  Widget _buildOpeningHoursField() {
    return Obx(
      () => OpeningHoursWidget(
        entries: controller.openingHoursEntries.toList(),
        onChanged: () {
          // Force refresh to update the display
          controller.openingHoursEntries.refresh();
        },
      ),
    );
  }

  /// Generic text field builder
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.chineseRed,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  /// Build phone numbers section
  Widget _buildPhoneNumbersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Phone Numbers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            TextButton.icon(
              onPressed: controller.addPhoneNumber,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.chineseRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.phoneNumbers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildPhoneNumberRow(index);
            },
          ),
        ),
      ],
    );
  }

  /// Build phone number row
  Widget _buildPhoneNumberRow(int index) {
    final entry = controller.phoneNumbers[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: entry.labelController,
                  decoration: const InputDecoration(
                    hintText: 'Label (e.g., Mobile)',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: AppColors.lightGray,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: entry.numberController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[\d\s\-\+\(\)]'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Phone number',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  validator: (value) {
                    // Only validate if number is provided
                    if (value != null && value.trim().isNotEmpty) {
                      final digits = value.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 7) {
                        return 'Too short';
                      }
                      if (digits.length > 15) {
                        return 'Too long';
                      }
                    }
                    return null;
                  },
                ),
              ),
              if (controller.phoneNumbers.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => controller.removePhoneNumber(index),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build media section
  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Media',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        _buildMediaPicker(),
        const SizedBox(height: 16),
        _buildMediaGrid(),
      ],
    );
  }

  /// Build media picker buttons
  Widget _buildMediaPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildMediaButton(
          icon: Icons.camera_alt,
          label: 'Camera',
          onTap: controller.pickImageFromCamera,
        ),
        _buildMediaButton(
          icon: Icons.photo_library,
          label: 'Gallery',
          onTap: controller.pickImageFromGallery,
        ),
      ],
    );
  }

  /// Build media button
  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightGray),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.chineseRed, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build media grid
  Widget _buildMediaGrid() {
    return Obx(() {
      if (controller.mediaItems.isEmpty) {
        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.lightGray,
              style: BorderStyle.solid,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 40,
                  color: AppColors.lightGray,
                ),
                SizedBox(height: 8),
                Text(
                  'No media added',
                  style: TextStyle(color: AppColors.mediumGray),
                ),
              ],
            ),
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: controller.mediaItems.length,
        itemBuilder: (context, index) {
          return _buildMediaItem(index);
        },
      );
    });
  }

  /// Build single media item
  Widget _buildMediaItem(int index) {
    final item = controller.mediaItems[index];
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (item.type == MediaType.image) {
              controller.setPrimaryMedia(index);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: item.isPrimary
                  ? Border.all(color: AppColors.chineseRed, width: 3)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(item.isPrimary ? 5 : 8),
              child: _buildMediaPreview(item),
            ),
          ),
        ),
        // Primary badge
        if (item.isPrimary)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.chineseRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Primary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => controller.removeMedia(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// Build media preview (image or video thumbnail)
  Widget _buildMediaPreview(MediaItem item) {
    if (item.isExisting && item.url != null) {
      return Image.network(
        item.url!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.lightGray,
          child: const Icon(Icons.broken_image, color: AppColors.mediumGray),
        ),
      );
    } else if (item.file != null) {
      return Image.file(
        item.file!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(color: AppColors.lightGray);
  }

  /// Build save button
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: controller.saveEntity,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.chineseRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Obx(
          () => Text(
            controller.isEditing.value ? 'Update Entity' : 'Create Entity',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  /// Build delete button (only in edit mode)
  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: controller.deleteEntity,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Delete Entity',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

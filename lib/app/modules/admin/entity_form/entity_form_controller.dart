import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'location_picker_page.dart';
import '../../../core/services/optimistic_update_service.dart';
import '../../../core/utils/media_helper.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/entity_model.dart';
import '../../../data/models/local/media_item.dart';
import '../../../data/models/phone_number_model.dart';
import '../../../widgets/opening_hours/opening_hours_widget.dart';

/// Controller for Entity Form (Add/Edit)
class EntityFormController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final OptimisticUpdateService _optimisticService =
      Get.find<OptimisticUpdateService>();
  final Uuid _uuid = const Uuid();

  // Form key
  final formKey = GlobalKey<FormState>();

  // Text controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();

  // Opening hours entries
  final RxList<OpeningHoursEntry> openingHoursEntries =
      <OpeningHoursEntry>[].obs;

  // Observable states
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final Rxn<String> selectedCategoryId = Rxn<String>();
  final RxList<PhoneNumberEntry> phoneNumbers = <PhoneNumberEntry>[].obs;
  final RxList<MediaItem> mediaItems = <MediaItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final RxBool isCategoriesLoading = true.obs;
  final Rxn<EntityModel> editingEntity = Rxn<EntityModel>();

  // Location
  final Rxn<double> latitude = Rxn<double>();
  final Rxn<double> longitude = Rxn<double>();
  final RxString pickedLocationAddress = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchCategories();

    // Check if editing existing entity
    final arguments = Get.arguments;
    if (arguments is EntityModel) {
      isEditing.value = true;
      editingEntity.value = arguments;
      _populateForm(arguments);
    } else {
      // Add one empty phone number field by default
      addPhoneNumber();
      // Initialize default opening hours for new entities
      openingHoursEntries.assignAll(OpeningHoursHelper.createDefault());
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    for (var entry in phoneNumbers) {
      entry.labelController.dispose();
      entry.numberController.dispose();
    }
    super.onClose();
  }

  /// Fetch categories for dropdown
  Future<void> _fetchCategories() async {
    isCategoriesLoading.value = true;
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name', ascending: true);

      categories.assignAll(
        (response as List).map((json) => CategoryModel.fromJson(json)).toList(),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load categories: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  /// Populate form with existing entity data
  void _populateForm(EntityModel entity) {
    nameController.text = entity.name;
    descriptionController.text = entity.description ?? '';
    addressController.text = entity.address ?? '';
    // Parse opening hours from stored string
    openingHoursEntries.assignAll(
      OpeningHoursHelper.parseFromString(entity.openingHours),
    );
    selectedCategoryId.value = entity.categoryId;
    latitude.value = entity.latitude;
    longitude.value = entity.longitude;

    if (entity.latitude != null && entity.longitude != null) {
      _updateAddressFromCoordinates(entity.latitude!, entity.longitude!);
    }

    // Populate phone numbers
    for (var phone in entity.phoneNumbers) {
      phoneNumbers.add(
        PhoneNumberEntry(
          labelController: TextEditingController(text: phone.label),
          numberController: TextEditingController(text: phone.number),
        ),
      );
    }
    if (phoneNumbers.isEmpty) {
      addPhoneNumber();
    }

    // Populate existing media
    if (entity.media != null) {
      for (var media in entity.media!) {
        if (media.isImage) {
          mediaItems.add(
            MediaItem(
              id: media.id,
              url: media.mediaUrl,
              type: MediaType.image,
              isPrimary: media.isPrimary,
              isExisting: true,
            ),
          );
        }
      }
    }
  }

  /// Select category
  void selectCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  /// Pick location on map
  Future<void> pickLocation() async {
    final result = await Get.to<LatLng>(
      () => LocationPickerPage(
        initialLatitude: latitude.value,
        initialLongitude: longitude.value,
      ),
    );

    if (result != null) {
      latitude.value = result.latitude;
      longitude.value = result.longitude;
      await _updateAddressFromCoordinates(result.latitude, result.longitude);
    }
  }

  /// Get address from coordinates
  Future<void> _updateAddressFromCoordinates(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Construct address components
        final components = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
          place.country,
        ].where((c) => c != null && c.isNotEmpty).toList();

        final address = components.join(', ');
        pickedLocationAddress.value = address;

        // Always update address field when picking from map
        addressController.text = address;
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      pickedLocationAddress.value =
          '${lat.toStringAsFixed(6)}, ${long.toStringAsFixed(6)}';
    }
  }

  /// Add phone number field
  void addPhoneNumber() {
    phoneNumbers.add(
      PhoneNumberEntry(
        labelController: TextEditingController(),
        numberController: TextEditingController(),
      ),
    );
  }

  /// Remove phone number field
  void removePhoneNumber(int index) {
    if (phoneNumbers.length > 1) {
      phoneNumbers[index].labelController.dispose();
      phoneNumbers[index].numberController.dispose();
      phoneNumbers.removeAt(index);
    }
  }

  /// Pick image from camera
  Future<void> pickImageFromCamera() async {
    final item = await MediaHelper.pickImageFromCamera();
    if (item != null) {
      item.isPrimary = mediaItems.isEmpty;
      mediaItems.add(item);
    }
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    final items = await MediaHelper.pickImagesFromGallery();
    for (var item in items) {
      item.isPrimary = mediaItems.isEmpty;
      mediaItems.add(item);
    }
  }

  /// Remove media
  void removeMedia(int index) {
    final item = mediaItems[index];
    if (item.isPrimary && mediaItems.length > 1) {
      // Set next item as primary
      final nextPrimary = mediaItems.firstWhereOrNull(
        (m) => m != item && m.type == MediaType.image,
      );
      if (nextPrimary != null) {
        nextPrimary.isPrimary = true;
      }
    }
    mediaItems.removeAt(index);
  }

  /// Set media as primary
  void setPrimaryMedia(int index) {
    for (int i = 0; i < mediaItems.length; i++) {
      mediaItems[i].isPrimary = i == index;
    }
    mediaItems.refresh();
  }

  /// Validate and save entity with optimistic update
  Future<void> saveEntity() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategoryId.value == null) {
      Get.snackbar(
        'Error',
        'Please select a category',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      String entityId;

      if (isEditing.value) {
        entityId = await _updateEntity();
      } else {
        entityId = await _createEntity();
      }

      // Upload new media
      await _uploadMedia(entityId);

      Get.back(result: true);
      Get.snackbar(
        'Success',
        isEditing.value
            ? 'Entity updated successfully'
            : 'Entity created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save entity: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Create new entity with optimistic update
  Future<String> _createEntity() async {
    final tempId = _uuid.v4();
    final now = DateTime.now();

    // Create optimistic entity
    final openingHoursString = _getOpeningHoursString();
    final optimisticEntity = EntityModel(
      id: tempId,
      categoryId: selectedCategoryId.value!,
      name: nameController.text.trim(),
      description: descriptionController.text.trim().isNotEmpty
          ? descriptionController.text.trim()
          : null,
      address: addressController.text.trim().isNotEmpty
          ? addressController.text.trim()
          : null,
      phoneNumbers: _getPhoneNumberModels(),
      openingHours: openingHoursString.isNotEmpty ? openingHoursString : null,
      latitude: latitude.value,
      longitude: longitude.value,
      createdAt: now,
      updatedAt: now,
    );

    // Optimistic add - UI updates instantly
    final result = await _optimisticService.addEntity(
      entity: optimisticEntity,
      apiCall: () async {
        final response = await _supabase
            .from('entities')
            .insert({
              'category_id': selectedCategoryId.value,
              'name': nameController.text.trim(),
              'description': descriptionController.text.trim().isNotEmpty
                  ? descriptionController.text.trim()
                  : null,
              'address': addressController.text.trim().isNotEmpty
                  ? addressController.text.trim()
                  : null,
              'phone_numbers': _getPhoneNumbers(),
              'opening_hours': openingHoursString.isNotEmpty
                  ? openingHoursString
                  : null,
              'latitude': latitude.value,
              'longitude': longitude.value,
            })
            .select('''
              *,
              entity_media(*)
            ''')
            .single();

        return EntityModel.fromJson(response);
      },
    );

    return result?.id ?? tempId;
  }

  /// Update existing entity with optimistic update
  Future<String> _updateEntity() async {
    final now = DateTime.now();
    final openingHoursString = _getOpeningHoursString();

    // Create updated entity
    final updatedEntity = editingEntity.value!.copyWith(
      categoryId: selectedCategoryId.value,
      name: nameController.text.trim(),
      description: descriptionController.text.trim().isNotEmpty
          ? descriptionController.text.trim()
          : null,
      address: addressController.text.trim().isNotEmpty
          ? addressController.text.trim()
          : null,
      phoneNumbers: _getPhoneNumberModels(),
      openingHours: openingHoursString.isNotEmpty ? openingHoursString : null,
      latitude: latitude.value,
      longitude: longitude.value,
      updatedAt: now,
    );

    // Optimistic update - UI updates instantly
    await _optimisticService.updateEntity(
      entity: updatedEntity,
      apiCall: () async {
        final response = await _supabase
            .from('entities')
            .update({
              'category_id': selectedCategoryId.value,
              'name': nameController.text.trim(),
              'description': descriptionController.text.trim().isNotEmpty
                  ? descriptionController.text.trim()
                  : null,
              'address': addressController.text.trim().isNotEmpty
                  ? addressController.text.trim()
                  : null,
              'phone_numbers': _getPhoneNumbers(),
              'opening_hours': openingHoursString.isNotEmpty
                  ? openingHoursString
                  : null,
              'latitude': latitude.value,
              'longitude': longitude.value,
              'updated_at': now.toIso8601String(),
            })
            .eq('id', editingEntity.value!.id)
            .select('''
              *,
              entity_media(*)
            ''')
            .single();

        return EntityModel.fromJson(response);
      },
    );

    return editingEntity.value!.id;
  }

  /// Get phone numbers as PhoneNumberModel list
  List<PhoneNumberModel> _getPhoneNumberModels() {
    return phoneNumbers
        .where(
          (entry) =>
              entry.labelController.text.trim().isNotEmpty ||
              entry.numberController.text.trim().isNotEmpty,
        )
        .map(
          (entry) => PhoneNumberModel(
            label: entry.labelController.text.trim(),
            number: entry.numberController.text.trim(),
          ),
        )
        .toList();
  }

  /// Get phone numbers as JSON list
  List<Map<String, String>> _getPhoneNumbers() {
    return phoneNumbers
        .where(
          (entry) =>
              entry.labelController.text.trim().isNotEmpty ||
              entry.numberController.text.trim().isNotEmpty,
        )
        .map(
          (entry) => {
            'label': entry.labelController.text.trim(),
            'number': entry.numberController.text.trim(),
          },
        )
        .toList();
  }

  /// Get opening hours as formatted string
  String _getOpeningHoursString() {
    return OpeningHoursHelper.entriesToString(openingHoursEntries);
  }

  /// Upload new media files
  Future<void> _uploadMedia(String entityId) async {
    final newMedia = mediaItems
        .where((m) => !m.isExisting && m.file != null)
        .toList();

    for (var media in newMedia) {
      try {
        final file = media.file!;
        final fileName =
            '${entityId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        const bucket = 'entity-images';

        // Upload to storage
        await _supabase.storage.from(bucket).upload(fileName, file);

        // Get public URL
        final publicUrl = _supabase.storage.from(bucket).getPublicUrl(fileName);

        // Insert media record
        await _supabase.from('entity_media').insert({
          'entity_id': entityId,
          'media_url': publicUrl,
          'media_type': 'image',
          'is_primary': media.isPrimary,
          'uploaded_by': _supabase.auth.currentUser?.id,
        });
      } catch (e) {
        print('Error uploading media: $e');
      }
    }
  }

  /// Delete entity
  Future<void> deleteEntity() async {
    if (editingEntity.value == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Entity'),
        content: Text(
          'Are you sure you want to delete "${editingEntity.value!.name}"?',
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
        // Optimistic delete - UI updates instantly
        await _optimisticService.deleteEntity(
          entityId: editingEntity.value!.id,
          apiCall: () async {
            // Delete media from storage first
            for (var media in mediaItems.where((m) => m.isExisting)) {
              try {
                final uri = Uri.parse(media.url!);
                final pathSegments = uri.pathSegments;
                const bucket = 'entity-images';
                final fileName = pathSegments.last;
                await _supabase.storage.from(bucket).remove([fileName]);
              } catch (e) {
                print('Error deleting media file: $e');
              }
            }

            // Delete entity (cascades to entity_media)
            await _supabase
                .from('entities')
                .delete()
                .eq('id', editingEntity.value!.id);
          },
        );

        Get.back(result: true);
        Get.snackbar(
          'Success',
          'Entity deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete entity: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }
}

/// Phone number entry with controllers
class PhoneNumberEntry {
  final TextEditingController labelController;
  final TextEditingController numberController;

  PhoneNumberEntry({
    required this.labelController,
    required this.numberController,
  });
}

import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/local/media_item.dart';

class MediaHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from camera
  static Future<MediaItem?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        return MediaItem(
          file: File(image.path),
          type: MediaType.image,
          isPrimary: false,
          isExisting: false,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to capture image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    return null;
  }

  /// Pick images from gallery
  static Future<List<MediaItem>> pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      return images
          .map(
            (image) => MediaItem(
              file: File(image.path),
              type: MediaType.image,
              isPrimary: false,
              isExisting: false,
            ),
          )
          .toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick images: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return [];
    }
  }
}

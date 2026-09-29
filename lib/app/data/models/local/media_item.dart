import 'dart:io';

/// Media type enum
enum MediaType { image, video }

/// Media item class for UI handling (picking/previewing)
class MediaItem {
  final String? id;
  final File? file;
  final String? url;
  final MediaType type;
  bool isPrimary;
  final bool isExisting;

  MediaItem({
    this.id,
    this.file,
    this.url,
    required this.type,
    this.isPrimary = false,
    required this.isExisting,
  });
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';

/// Enhanced cached network image widget with offline support
/// Handles loading, errors, and provides consistent styling
class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? placeholderColor;
  final IconData placeholderIcon;
  final double placeholderIconSize;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.placeholderColor,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderIconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
      placeholder: (context, url) => placeholder ?? _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildErrorPlaceholder(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? AppColors.lightGray.withOpacity(0.3),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.chineseRed.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor ?? AppColors.lightGray.withOpacity(0.3),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: placeholderIconSize,
          color: AppColors.mediumGray,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? AppColors.lightGray.withOpacity(0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: placeholderIconSize,
            color: AppColors.mediumGray,
          ),
          const SizedBox(height: 4),
          Text(
            'Image unavailable',
            style: TextStyle(fontSize: 10, color: AppColors.mediumGray),
          ),
        ],
      ),
    );
  }
}

/// Category image with consistent styling
class CategoryImage extends StatelessWidget {
  final String? imageUrl;
  final String categoryName;
  final double size;
  final BorderRadius? borderRadius;

  const CategoryImage({
    super.key,
    required this.imageUrl,
    required this.categoryName,
    this.size = 80,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildTextPlaceholder();
    }

    return CachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      placeholderIcon: Icons.category_outlined,
      errorWidget: _buildTextPlaceholder(),
    );
  }

  Widget _buildTextPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.chineseRed.withOpacity(0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          categoryName.isNotEmpty ? categoryName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: AppColors.chineseRed,
          ),
        ),
      ),
    );
  }
}

/// Entity thumbnail with consistent styling
class EntityThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const EntityThumbnail({
    super.key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = 150,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      placeholderIcon: Icons.place_outlined,
      placeholderIconSize: 48,
    );
  }
}

/// User avatar with consistent styling
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double size;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    this.size = 48,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return _buildInitialsAvatar();
    }

    return ClipOval(
      child: CachedImage(
        imageUrl: avatarUrl,
        width: size,
        height: size,
        placeholderIcon: Icons.person_outline,
        placeholderIconSize: size * 0.5,
        errorWidget: _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    String initials = '?';
    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = displayName[0].toUpperCase();
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.chineseRed.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: AppColors.chineseRed,
          ),
        ),
      ),
    );
  }
}

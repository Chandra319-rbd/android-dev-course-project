import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';

/// Fullscreen image viewer with swipe gestures and zoom support
class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final VoidCallback? onClose;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.onClose,
  });

  /// Show fullscreen image viewer as a modal route
  static Future<void> show({
    required BuildContext context,
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullscreenImageViewer(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
            onClose: () => Navigator.of(context).pop(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;

  // For vertical drag to dismiss
  double _dragOffset = 0;
  double _dragScale = 1.0;
  bool _isDragging = false;

  // For zoom
  final TransformationController _transformController =
      TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Set system UI to immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Reset zoom when page changes
    _transformController.value = Matrix4.identity();
    _isZoomed = false;
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    if (_isZoomed) return;
    setState(() {
      _isDragging = true;
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_isZoomed) return;
    setState(() {
      _dragOffset += details.delta.dy;
      // Calculate scale based on drag (shrink as user drags down)
      _dragScale = 1.0 - (_dragOffset.abs() / 500).clamp(0.0, 0.3);
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_isZoomed) return;

    final velocity = details.primaryVelocity ?? 0;

    // If dragged far enough or fast enough, close
    if (_dragOffset.abs() > 100 || velocity.abs() > 500) {
      widget.onClose?.call();
    } else {
      // Snap back
      setState(() {
        _dragOffset = 0;
        _dragScale = 1.0;
        _isDragging = false;
      });
    }
  }

  void _onInteractionStart(ScaleStartDetails details) {
    // Check if starting a zoom gesture
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    // Update zoom state
    final scale = _transformController.value.getMaxScaleOnAxis();
    setState(() {
      _isZoomed = scale > 1.05;
    });
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    final scale = _transformController.value.getMaxScaleOnAxis();
    setState(() {
      _isZoomed = scale > 1.05;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.black.withValues(
      alpha: (1.0 - (_dragOffset.abs() / 300).clamp(0.0, 0.5)),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Image gallery
          GestureDetector(
            onVerticalDragStart: _handleVerticalDragStart,
            onVerticalDragUpdate: _handleVerticalDragUpdate,
            onVerticalDragEnd: _handleVerticalDragEnd,
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Transform.scale(
                scale: _dragScale,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: _isZoomed
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  itemCount: widget.imageUrls.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      transformationController: _transformController,
                      onInteractionStart: _onInteractionStart,
                      onInteractionUpdate: _onInteractionUpdate,
                      onInteractionEnd: _onInteractionEnd,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Center(
                        child: _buildImage(widget.imageUrls[index]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Top bar with close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _isDragging ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      _buildIconButton(
                        icon: Icons.close,
                        onTap: widget.onClose,
                      ),
                      // Page indicator
                      if (widget.imageUrls.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${widget.imageUrls.length}',
                            style: const TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      // Placeholder for symmetry
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom indicator dots
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _isDragging ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.imageUrls.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentIndex == index
                                ? AppColors.pureWhite
                                : AppColors.pureWhite.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Swipe hint
          if (!_isDragging && !_isZoomed)
            Positioned(
              bottom: widget.imageUrls.length > 1 ? 60 : 20,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: 0.6,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.pureWhite.withValues(alpha: 0.6),
                        size: 24,
                      ),
                      Text(
                        'Swipe down to close',
                        style: TextStyle(
                          color: AppColors.pureWhite.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.pureWhite, size: 24),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: AppColors.pureWhite),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image, color: AppColors.pureWhite, size: 64),
        ),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: AppColors.pureWhite, size: 64),
        ),
      );
    }
  }
}

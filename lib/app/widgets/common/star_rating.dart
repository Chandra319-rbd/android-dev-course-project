import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A customizable star rating widget for displaying and selecting ratings
class StarRating extends StatelessWidget {
  /// Current rating value (0-5)
  final double rating;

  /// Maximum rating value (default 5)
  final int maxRating;

  /// Size of each star
  final double starSize;

  /// Color of filled stars
  final Color filledColor;

  /// Color of empty stars
  final Color emptyColor;

  /// Spacing between stars
  final double spacing;

  /// Whether the rating is editable
  final bool isEditable;

  /// Callback when rating changes (only used if isEditable is true)
  final ValueChanged<double>? onRatingChanged;

  /// Whether to show half stars
  final bool allowHalfRating;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.starSize = 24,
    this.filledColor = AppColors.imperialGold,
    this.emptyColor = AppColors.lightGray,
    this.spacing = 4,
    this.isEditable = false,
    this.onRatingChanged,
    this.allowHalfRating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starValue = index + 1;
        IconData icon;
        Color color;

        if (rating >= starValue) {
          // Full star
          icon = Icons.star;
          color = filledColor;
        } else if (allowHalfRating && rating >= starValue - 0.5) {
          // Half star
          icon = Icons.star_half;
          color = filledColor;
        } else {
          // Empty star
          icon = Icons.star_border;
          color = emptyColor;
        }

        final star = Icon(icon, size: starSize, color: color);

        if (isEditable) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: GestureDetector(
              onTap: () => onRatingChanged?.call(starValue.toDouble()),
              onHorizontalDragUpdate: allowHalfRating
                  ? (details) {
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(
                        details.globalPosition,
                      );
                      final starWidth = starSize + spacing;
                      final newRating = (localPosition.dx / starWidth).clamp(
                        0.5,
                        5.0,
                      );
                      final roundedRating = (newRating * 2).round() / 2;
                      onRatingChanged?.call(roundedRating);
                    }
                  : null,
              child: star,
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: star,
        );
      }),
    );
  }
}

/// Interactive star rating widget with animation
class InteractiveStarRating extends StatefulWidget {
  /// Initial rating value
  final double initialRating;

  /// Maximum rating value (default 5)
  final int maxRating;

  /// Size of each star
  final double starSize;

  /// Color of filled stars
  final Color filledColor;

  /// Color of empty stars
  final Color emptyColor;

  /// Spacing between stars
  final double spacing;

  /// Callback when rating changes
  final ValueChanged<int>? onRatingChanged;

  /// Whether the rating widget is enabled
  final bool enabled;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.starSize = 40,
    this.filledColor = AppColors.imperialGold,
    this.emptyColor = AppColors.lightGray,
    this.spacing = 8,
    this.onRatingChanged,
    this.enabled = true,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating>
    with SingleTickerProviderStateMixin {
  late int _currentRating;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating.round();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateRating(int newRating) {
    if (!widget.enabled) return;

    setState(() {
      _currentRating = newRating;
    });
    _controller.forward(from: 0);
    widget.onRatingChanged?.call(newRating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starValue = index + 1;
        final isFilled = _currentRating >= starValue;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          child: GestureDetector(
            onTap: () => _updateRating(starValue),
            child: AnimatedScale(
              scale: isFilled && _currentRating == starValue ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  size: widget.starSize,
                  color: isFilled
                      ? widget.filledColor
                      : widget.enabled
                      ? widget.emptyColor
                      : widget.emptyColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Compact star rating display for cards and lists
class CompactStarRating extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double starSize;
  final TextStyle? textStyle;

  const CompactStarRating({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.starSize = 16,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: starSize, color: AppColors.imperialGold),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style:
              textStyle ??
              TextStyle(
                fontSize: starSize * 0.875,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
        ),
        if (reviewCount > 0) ...[
          Text(
            ' ($reviewCount)',
            style:
                textStyle?.copyWith(
                  fontWeight: FontWeight.normal,
                  color: AppColors.mediumGray,
                ) ??
                TextStyle(
                  fontSize: starSize * 0.75,
                  color: AppColors.mediumGray,
                ),
          ),
        ],
      ],
    );
  }
}

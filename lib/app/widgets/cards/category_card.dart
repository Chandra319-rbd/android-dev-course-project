import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/category_model.dart';

/// Category card widget for grid display
class CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Parse color from hex string
    final Color categoryColor = _parseColor(widget.category.color);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image or gradient
                if (widget.category.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: widget.category.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            categoryColor.withOpacity(0.4),
                            categoryColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildGradientBackground(categoryColor),
                  )
                else
                  _buildGradientBackground(categoryColor),

                // Overlay gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.55),
                      ],
                      stops: const [0.2, 0.6, 1.0],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container with glow effect
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconData(widget.category.iconName),
                          color: categoryColor,
                          size: 26,
                        ),
                      ),
                      const Spacer(),
                      // Category name
                      Text(
                        widget.category.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Decorative corner accent
                Positioned(
                  top: -25,
                  right: -25,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -15,
                  left: -15,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBackground(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.6), color.withOpacity(0.9)],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      // Remove # if present and parse hex
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add alpha if not present
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return AppColors.chineseRed; // Default fallback
    }
  }

  IconData _getIconData(String iconName) {
    // Map common icon names to Material Icons
    final Map<String, IconData> iconMap = {
      'restaurant': Icons.restaurant,
      'food': Icons.restaurant,
      'hotel': Icons.hotel,
      'lodging': Icons.hotel,
      'store': Icons.store,
      'shop': Icons.store,
      'shopping': Icons.shopping_bag,
      'temple': Icons.temple_buddhist,
      'worship': Icons.temple_buddhist,
      'park': Icons.park,
      'nature': Icons.park,
      'medical': Icons.local_hospital,
      'hospital': Icons.local_hospital,
      'school': Icons.school,
      'education': Icons.school,
      'entertainment': Icons.movie,
      'movie': Icons.movie,
      'sports': Icons.sports,
      'gym': Icons.fitness_center,
      'bank': Icons.account_balance,
      'atm': Icons.atm,
      'gas': Icons.local_gas_station,
      'fuel': Icons.local_gas_station,
      'parking': Icons.local_parking,
      'cafe': Icons.local_cafe,
      'coffee': Icons.local_cafe,
      'bar': Icons.local_bar,
      'pharmacy': Icons.local_pharmacy,
      'library': Icons.local_library,
      'post': Icons.local_post_office,
      'police': Icons.local_police,
      'fire': Icons.local_fire_department,
      'airport': Icons.local_airport,
      'taxi': Icons.local_taxi,
      'bus': Icons.directions_bus,
      'train': Icons.train,
      'attraction': Icons.attractions,
      'landmark': Icons.flag,
      'beach': Icons.beach_access,
      'pool': Icons.pool,
      'spa': Icons.spa,
      'salon': Icons.content_cut,
      'laundry': Icons.local_laundry_service,
      'car': Icons.directions_car,
      'repair': Icons.build,
      'service': Icons.miscellaneous_services,
      'government': Icons.account_balance,
      'office': Icons.business,
      'home': Icons.home,
      'apartment': Icons.apartment,
      'place': Icons.place,
      'default': Icons.category,
    };

    final String key = iconName.toLowerCase();
    return iconMap[key] ?? Icons.category;
  }
}

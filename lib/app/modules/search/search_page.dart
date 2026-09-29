import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/cards/entity_card.dart';
import '../../widgets/common/connectivity_indicator.dart';
import 'search_controller.dart' as search;

/// Search Screen with auto-focus search bar
class SearchPage extends GetView<search.SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: _buildAppBar(),
      body: ConnectivityIndicator(
        showBanner: false,
        child: Obx(() {
          // Show recent searches if not searched yet
          if (!controller.hasSearched.value) {
            return _buildRecentSearches();
          }

          // Show loading
          if (controller.isSearching.value) {
            return _buildLoadingView();
          }

          // Show results or empty state
          if (controller.searchResults.isEmpty) {
            return _buildEmptyResults();
          }

          return _buildSearchResults();
        }),
      ),
    );
  }

  /// Build app bar with search field
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.chineseRed,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.warmCream),
        onPressed: () => Get.back(),
      ),
      title: _buildSearchField(),
      actions: [
        Obx(
          () => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.warmCream),
                  onPressed: controller.clearSearch,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Build search text field
  Widget _buildSearchField() {
    // Don't autofocus if showing all entities
    final showAll = Get.arguments != null && Get.arguments['showAll'] == true;
    return TextField(
      autofocus: !showAll,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.bodyLarge.copyWith(color: Colors.black),
      cursorColor: AppColors.imperialGold,
      decoration: InputDecoration(
        hintText: 'Search places...',
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: Colors.black54),
        border: InputBorder.none,
      ),
      onChanged: (value) {
        controller.searchQuery.value = value;
      },
      onSubmitted: (value) {
        controller.search(value);
      },
    );
  }

  /// Build recent searches
  Widget _buildRecentSearches() {
    return Obx(() {
      if (controller.recentSearches.isEmpty) {
        return _buildSearchHint();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: controller.clearRecentSearches,
                  child: Text(
                    'Clear All',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.chineseRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: controller.recentSearches.length,
              itemBuilder: (context, index) {
                final query = controller.recentSearches[index];
                return ListTile(
                  leading: const Icon(
                    Icons.history,
                    color: AppColors.mediumGray,
                  ),
                  title: Text(query, style: AppTextStyles.bodyMedium),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.mediumGray,
                    ),
                    onPressed: () => controller.removeRecentSearch(query),
                  ),
                  onTap: () {
                    controller.search(query);
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }

  /// Build search hint when no recent searches
  Widget _buildSearchHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: AppColors.mediumGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Search for Places',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find restaurants, hotels, shops, and more in the village.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build loading view
  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.chineseRed),
    );
  }

  /// Build empty results view
  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.mediumGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Found',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Text(
                'No places matching "${controller.searchQuery.value}"',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.mediumGray,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Try a different search term',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build search results
  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Obx(
            () => Text(
              controller.showingAll.value
                  ? '${controller.searchResults.length} place${controller.searchResults.length != 1 ? 's' : ''}'
                  : '${controller.searchResults.length} result${controller.searchResults.length != 1 ? 's' : ''} found',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(
            () => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                final entity = controller.searchResults[index];
                return EntityCard(
                  entity: entity,
                  onTap: () => controller.goToEntityDetail(entity),
                  isCompact: true,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

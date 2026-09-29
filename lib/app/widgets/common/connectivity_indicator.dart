import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/theme/app_colors.dart';

/// Widget that displays the current connectivity status
/// Shows a banner when offline and syncing indicator when reconnecting
class ConnectivityIndicator extends StatelessWidget {
  final Widget child;
  final bool showBanner;

  const ConnectivityIndicator({
    super.key,
    required this.child,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    // Check if service is registered before using it
    if (!Get.isRegistered<ConnectivityService>()) {
      return child;
    }

    final connectivityService = Get.find<ConnectivityService>();

    return Column(
      children: [
        // Offline Banner
        if (showBanner)
          Obx(() {
            if (!connectivityService.isOnline.value) {
              return const OfflineBanner();
            }
            // Show syncing banner briefly after reconnection
            if (connectivityService.wasOffline.value) {
              return const SyncingBanner();
            }
            return const SizedBox.shrink();
          }),
        // Main content
        Expanded(child: child),
      ],
    );
  }
}

/// Banner shown when device is offline
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkGray.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.warmCream,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'You\'re offline - Viewing cached data',
              style: TextStyle(
                color: AppColors.warmCream.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner shown when syncing after reconnection
class SyncingBanner extends StatefulWidget {
  const SyncingBanner({super.key});

  @override
  State<SyncingBanner> createState() => _SyncingBannerState();
}

class _SyncingBannerState extends State<SyncingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Auto-hide after sync completes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Get.isRegistered<ConnectivityService>()) {
        Get.find<ConnectivityService>().resetOfflineFlag();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.jadeGreen.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: const Icon(
                Icons.sync_rounded,
                color: AppColors.pureWhite,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Back online - Syncing...',
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small connectivity status indicator for app bars
class ConnectivityStatusIcon extends StatelessWidget {
  final double size;
  final bool showLabel;

  const ConnectivityStatusIcon({
    super.key,
    this.size = 20,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) {
      return const SizedBox.shrink();
    }

    final connectivityService = Get.find<ConnectivityService>();

    return Obx(() {
      final isOffline = !connectivityService.isOnline.value;

      if (!isOffline && !showLabel) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: showLabel ? 10 : 6,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isOffline
              ? AppColors.darkGray.withOpacity(0.2)
              : AppColors.jadeGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
              size: size,
              color: isOffline ? AppColors.mediumGray : AppColors.jadeGreen,
            ),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                connectivityService.statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isOffline ? AppColors.mediumGray : AppColors.jadeGreen,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

/// Wrap any widget to show offline overlay when not connected
class OfflineAwareWidget extends StatelessWidget {
  final Widget child;
  final Widget? offlineChild;
  final bool showOfflineOverlay;

  const OfflineAwareWidget({
    super.key,
    required this.child,
    this.offlineChild,
    this.showOfflineOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) {
      return child;
    }

    final connectivityService = Get.find<ConnectivityService>();

    return Obx(() {
      if (!connectivityService.isOnline.value && showOfflineOverlay) {
        return Stack(
          children: [
            child,
            if (offlineChild != null) Positioned.fill(child: offlineChild!),
          ],
        );
      }
      return child;
    });
  }
}

/// Button that's disabled when offline
class OnlineRequiredButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? offlineMessage;

  const OnlineRequiredButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.offlineMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) {
      return ElevatedButton(onPressed: onPressed, child: child);
    }

    final connectivityService = Get.find<ConnectivityService>();

    return Obx(() {
      final isOffline = !connectivityService.isOnline.value;

      return ElevatedButton(
        onPressed: isOffline
            ? () {
                Get.snackbar(
                  'Offline',
                  offlineMessage ?? 'This action requires internet connection.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.darkGray,
                  colorText: AppColors.warmCream,
                  icon: const Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.warmCream,
                  ),
                );
              }
            : onPressed,
        style: isOffline
            ? ElevatedButton.styleFrom(backgroundColor: AppColors.lightGray)
            : null,
        child: child,
      );
    });
  }
}

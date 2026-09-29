import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Service for monitoring network connectivity
/// Provides reactive connectivity state and offline mode handling
class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  // Reactive connectivity state
  final Rx<ConnectivityStatus> status = ConnectivityStatus.online.obs;
  final RxBool isOnline = true.obs;
  final RxBool wasOffline = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Callbacks for connectivity changes
  final List<VoidCallback> _onOnlineCallbacks = [];
  final List<VoidCallback> _onOfflineCallbacks = [];

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _startListening();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  /// Initialize connectivity status
  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      print('Error checking connectivity: $e');
      // Assume online if we can't check
      status.value = ConnectivityStatus.online;
      isOnline.value = true;
    }
  }

  /// Start listening for connectivity changes
  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
      onError: (e) {
        print('Connectivity stream error: $e');
      },
    );
  }

  /// Update status based on connectivity results
  void _updateStatus(List<ConnectivityResult> results) {
    final previouslyOnline = isOnline.value;

    // Check if any connection is available
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (hasConnection) {
      // Determine connection type
      if (results.contains(ConnectivityResult.wifi)) {
        status.value = ConnectivityStatus.wifi;
      } else if (results.contains(ConnectivityResult.mobile)) {
        status.value = ConnectivityStatus.mobile;
      } else if (results.contains(ConnectivityResult.ethernet)) {
        status.value = ConnectivityStatus.ethernet;
      } else {
        status.value = ConnectivityStatus.online;
      }
      isOnline.value = true;

      // If we were offline and now online, trigger callbacks
      if (!previouslyOnline) {
        wasOffline.value = true;
        _notifyOnline();
        _showConnectedSnackbar();
      }
    } else {
      status.value = ConnectivityStatus.offline;
      isOnline.value = false;

      // If we were online and now offline, trigger callbacks
      if (previouslyOnline) {
        _notifyOffline();
        _showOfflineSnackbar();
      }
    }
  }

  /// Show snackbar when device goes offline
  void _showOfflineSnackbar() {
    if (Get.context != null) {
      Get.showSnackbar(
        GetSnackBar(
          message: 'You are offline. Showing cached data.',
          icon: const Icon(Icons.cloud_off_rounded, color: AppColors.warmCream),
          backgroundColor: AppColors.darkGray,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        ),
      );
    }
  }

  /// Show snackbar when device comes back online
  void _showConnectedSnackbar() {
    if (Get.context != null) {
      Get.showSnackbar(
        GetSnackBar(
          message: 'Back online! Syncing data...',
          icon: const Icon(
            Icons.cloud_done_rounded,
            color: AppColors.warmCream,
          ),
          backgroundColor: AppColors.jadeGreen,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        ),
      );
    }
  }

  /// Register callback for when device comes online
  void addOnlineCallback(VoidCallback callback) {
    _onOnlineCallbacks.add(callback);
  }

  /// Remove online callback
  void removeOnlineCallback(VoidCallback callback) {
    _onOnlineCallbacks.remove(callback);
  }

  /// Register callback for when device goes offline
  void addOfflineCallback(VoidCallback callback) {
    _onOfflineCallbacks.add(callback);
  }

  /// Remove offline callback
  void removeOfflineCallback(VoidCallback callback) {
    _onOfflineCallbacks.remove(callback);
  }

  /// Notify all online callbacks
  void _notifyOnline() {
    for (final callback in _onOnlineCallbacks) {
      callback();
    }
  }

  /// Notify all offline callbacks
  void _notifyOffline() {
    for (final callback in _onOfflineCallbacks) {
      callback();
    }
  }

  /// Check connectivity manually
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return isOnline.value;
    } catch (e) {
      return isOnline.value;
    }
  }

  /// Reset the wasOffline flag after sync is complete
  void resetOfflineFlag() {
    wasOffline.value = false;
  }

  /// Get status icon
  IconData get statusIcon {
    switch (status.value) {
      case ConnectivityStatus.wifi:
        return Icons.wifi;
      case ConnectivityStatus.mobile:
        return Icons.signal_cellular_alt;
      case ConnectivityStatus.ethernet:
        return Icons.lan;
      case ConnectivityStatus.online:
        return Icons.cloud_done_outlined;
      case ConnectivityStatus.offline:
        return Icons.cloud_off_outlined;
    }
  }

  /// Get status color
  Color get statusColor {
    switch (status.value) {
      case ConnectivityStatus.offline:
        return AppColors.mediumGray;
      default:
        return AppColors.jadeGreen;
    }
  }

  /// Get status text
  String get statusText {
    switch (status.value) {
      case ConnectivityStatus.wifi:
        return 'WiFi';
      case ConnectivityStatus.mobile:
        return 'Mobile';
      case ConnectivityStatus.ethernet:
        return 'Ethernet';
      case ConnectivityStatus.online:
        return 'Online';
      case ConnectivityStatus.offline:
        return 'Offline';
    }
  }
}

/// Connectivity status types
enum ConnectivityStatus { wifi, mobile, ethernet, online, offline }

import 'package:flutter/foundation.dart';

/// Simple logger utility for the app
/// In production, print statements are disabled
class AppLogger {
  AppLogger._();

  static void debug(String message, [dynamic error]) {
    if (kDebugMode) {
      debugPrint('🔵 DEBUG: $message');
      if (error != null) debugPrint('   Error: $error');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  static void warning(String message, [dynamic error]) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: $message');
      if (error != null) debugPrint('   Error: $error');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: $message');
      if (error != null) debugPrint('   Error: $error');
      if (stackTrace != null) debugPrint('   Stack: $stackTrace');
    }
  }
}

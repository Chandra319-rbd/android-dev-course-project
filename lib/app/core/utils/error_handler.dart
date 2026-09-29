import 'package:supabase_flutter/supabase_flutter.dart';

/// Custom exception classes for better error handling
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network connection error'])
    : super(message, code: 'NETWORK_ERROR');
}

class AuthException extends AppException {
  AuthException(String message, {dynamic originalError})
    : super(message, code: 'AUTH_ERROR', originalError: originalError);
}

class DatabaseException extends AppException {
  DatabaseException(String message, {dynamic originalError})
    : super(message, code: 'DATABASE_ERROR', originalError: originalError);
}

class StorageException extends AppException {
  StorageException(String message, {dynamic originalError})
    : super(message, code: 'STORAGE_ERROR', originalError: originalError);
}

/// Helper to parse Supabase errors into user-friendly messages
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      return _parsePostgrestError(error);
    } else if (error is StorageException) {
      return 'File upload failed. Please try again.';
    } else if (error is AuthException) {
      return _parseAuthError(error);
    } else if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  static String _parsePostgrestError(PostgrestException error) {
    if (error.code == '23505') {
      return 'This item already exists.';
    } else if (error.code == '23503') {
      return 'Cannot delete. This item is being used elsewhere.';
    }
    return error.message;
  }

  static String _parseAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login')) {
      return 'Invalid email or password.';
    } else if (message.contains('email not confirmed')) {
      return 'Please confirm your email address.';
    } else if (message.contains('user already registered')) {
      return 'This email is already registered.';
    }
    return 'Authentication failed. Please try again.';
  }
}

import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] ${DateTime.now().toIso8601String()}: $message');
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] ${DateTime.now().toIso8601String()}: $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }

  static void i(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] ${DateTime.now().toIso8601String()}: $message');
    }
  }
}

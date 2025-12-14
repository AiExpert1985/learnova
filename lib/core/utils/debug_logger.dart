/// Simple debug logger for console output
library;

/// Simple debug logger - just prints to console with timestamp
class DebugLogger {
  /// Log a message to console
  static void log(String message, {DebugLogLevel? level}) {
    final timestamp = DateTime.now().toString().substring(11, 23);
    print('[$timestamp] $message');
  }

  // Deprecated methods kept for backward compatibility - do nothing
  static void setDebugMode(bool enabled) {}
  static void setScaffoldMessengerKey(dynamic key) {}
}

/// Debug log levels (kept for backward compatibility)
enum DebugLogLevel { info, success, warning, error }

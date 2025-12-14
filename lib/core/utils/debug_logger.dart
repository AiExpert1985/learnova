/// Debug logger with optional snackbar display
library;

import 'package:flutter/material.dart';

/// Debug logger service for tracking app behavior during testing
/// Logs to console always, optionally shows snackbars in debug mode
class DebugLogger {
  static bool _debugMode = false;
  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  /// Enable or disable debug mode (snackbar display)
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }

  /// Set the scaffold messenger key for showing snackbars
  static void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }

  /// Log a debug message
  /// Always prints to console, shows snackbar if debug mode is enabled
  static void log(String message, {DebugLogLevel level = DebugLogLevel.info}) {
    // Always log to console
    final timestamp = DateTime.now().toString().substring(11, 23);
    final prefix = _getLevelPrefix(level);
    print('[$timestamp] $prefix $message');

    // Show snackbar if debug mode is enabled
    if (_debugMode && _scaffoldMessengerKey?.currentState != null) {
      _showSnackbar(message, level);
    }
  }

  static String _getLevelPrefix(DebugLogLevel level) {
    switch (level) {
      case DebugLogLevel.info:
        return '[INFO]';
      case DebugLogLevel.success:
        return '[✓]';
      case DebugLogLevel.warning:
        return '[⚠]';
      case DebugLogLevel.error:
        return '[✗]';
    }
  }

  static void _showSnackbar(String message, DebugLogLevel level) {
    final color = _getLevelColor(level);
    final icon = _getLevelIcon(level);

    _scaffoldMessengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 8, right: 8),
      ),
    );
  }

  static Color _getLevelColor(DebugLogLevel level) {
    switch (level) {
      case DebugLogLevel.info:
        return Colors.blue.shade700;
      case DebugLogLevel.success:
        return Colors.green.shade700;
      case DebugLogLevel.warning:
        return Colors.orange.shade700;
      case DebugLogLevel.error:
        return Colors.red.shade700;
    }
  }

  static IconData _getLevelIcon(DebugLogLevel level) {
    switch (level) {
      case DebugLogLevel.info:
        return Icons.info_outline;
      case DebugLogLevel.success:
        return Icons.check_circle_outline;
      case DebugLogLevel.warning:
        return Icons.warning_amber_outlined;
      case DebugLogLevel.error:
        return Icons.error_outline;
    }
  }
}

/// Debug log levels
enum DebugLogLevel {
  info,
  success,
  warning,
  error,
}

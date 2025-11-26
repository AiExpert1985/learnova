import 'dart:convert';
import 'dart:io';

/// Reads configuration from config.json file
class ConfigService {
  static Map<String, dynamic>? _config;

  /// Load configuration from config.json
  static Future<void> load() async {
    try {
      final file = File('config.json');
      if (!await file.exists()) {
        _config = {};
        return;
      }

      final contents = await file.readAsString();
      _config = jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      _config = {};
    }
  }

  /// Get a configuration value
  static String get(String key, {String defaultValue = ''}) {
    return _config?[key] as String? ?? defaultValue;
  }

  /// Check if config is loaded
  static bool get isLoaded => _config != null;
}

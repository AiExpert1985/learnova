import 'dart:convert';
import 'dart:io';

/// Reads configuration from environment variables or config.json file
/// Priority: Environment variables > config.json file
class ConfigService {
  static Map<String, dynamic>? _config;

  /// Load configuration from environment or file
  static Future<void> load() async {
    _config = {};

    // Try loading from file first (for desktop development)
    try {
      final file = File('config.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        _config = jsonDecode(contents) as Map<String, dynamic>;
      }
    } catch (e) {
      // File loading failed (expected on mobile), continue
    }

    // Override with environment variables (works on all platforms)
    // This allows mobile builds to work via --dart-define
    const envApiKey = String.fromEnvironment('OPENAI_API_KEY');
    if (envApiKey.isNotEmpty) {
      _config!['OPENAI_API_KEY'] = envApiKey;
    }
  }

  /// Get a configuration value
  static String get(String key, {String defaultValue = ''}) {
    return _config?[key] as String? ?? defaultValue;
  }

  /// Check if config is loaded
  static bool get isLoaded => _config != null;
}

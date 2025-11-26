/// Reads configuration from compile-time environment variables
/// Standard Flutter approach using --dart-define
class ConfigService {
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');

  /// Get API key from environment
  static String get apiKey => _apiKey;

  /// Check if API key is configured
  static bool get hasApiKey => _apiKey.isNotEmpty;
}
